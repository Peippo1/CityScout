-- CityScout: saved_itineraries schema
-- Run this in the Supabase SQL Editor (SQL Editor → New query).
-- Re-running is safe — all statements are idempotent.
--
-- Fields:
--   id                       surrogate primary key
--   user_id                  FK → auth.users, cascades on user deletion
--   destination              plain-text city name, indexed with user_id
--   title                    short itinerary title for list display
--   summary                  optional one-line description for list display
--   raw_response             full PlanItineraryResponse JSON from the backend
--   structured_itinerary_json normalised display format; populated on save,
--                            intended as the portable format for iOS sync
--   created_at / updated_at  timestamps; updated_at is kept current by trigger
--
-- Extensibility notes:
--   Add columns for trip_id, tags[], or sync_status as features evolve.
--   structured_itinerary_json decouples the display format from the backend
--   contract so iOS can consume it without parsing raw_response.

-- -------------------------------------------------------
-- Extension (needed for moddatetime trigger)
-- -------------------------------------------------------
create extension if not exists moddatetime schema extensions;

-- -------------------------------------------------------
-- Table
-- -------------------------------------------------------
create table if not exists public.saved_itineraries (
  id                        uuid        not null default gen_random_uuid() primary key,
  user_id                   uuid        not null references auth.users(id) on delete cascade,
  destination               text        not null,
  title                     text        not null,
  summary                   text,
  raw_response              jsonb       not null,
  structured_itinerary_json jsonb,
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now()
);

-- -------------------------------------------------------
-- updated_at trigger
-- -------------------------------------------------------
create or replace trigger saved_itineraries_moddatetime
  before update on public.saved_itineraries
  for each row execute procedure extensions.moddatetime(updated_at);

-- -------------------------------------------------------
-- Migration from v1 schema (payload column)
-- Run only if upgrading from the previous schema version.
-- -------------------------------------------------------
do $$ begin
  -- Rename payload → raw_response if the old column still exists.
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name   = 'saved_itineraries'
      and column_name  = 'payload'
  ) then
    alter table public.saved_itineraries
      rename column payload to raw_response;
  end if;

  -- Add structured_itinerary_json if missing.
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name   = 'saved_itineraries'
      and column_name  = 'structured_itinerary_json'
  ) then
    alter table public.saved_itineraries
      add column structured_itinerary_json jsonb;
  end if;

  -- Add updated_at if missing.
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name   = 'saved_itineraries'
      and column_name  = 'updated_at'
  ) then
    alter table public.saved_itineraries
      add column updated_at timestamptz not null default now();
  end if;
end $$;

-- -------------------------------------------------------
-- Row Level Security
-- -------------------------------------------------------
alter table public.saved_itineraries enable row level security;

-- Users may only read their own rows.
do $$ begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'saved_itineraries' and policyname = 'users_select_own'
  ) then
    create policy "users_select_own"
      on public.saved_itineraries
      for select
      using (auth.uid() = user_id);
  end if;
end $$;

-- Users may only insert rows that belong to themselves.
do $$ begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'saved_itineraries' and policyname = 'users_insert_own'
  ) then
    create policy "users_insert_own"
      on public.saved_itineraries
      for insert
      with check (auth.uid() = user_id);
  end if;
end $$;

-- Users may only delete their own rows.
do $$ begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'saved_itineraries' and policyname = 'users_delete_own'
  ) then
    create policy "users_delete_own"
      on public.saved_itineraries
      for delete
      using (auth.uid() = user_id);
  end if;
end $$;

-- -------------------------------------------------------
-- Index
-- -------------------------------------------------------
create index if not exists saved_itineraries_user_id_created_at
  on public.saved_itineraries (user_id, created_at desc);
