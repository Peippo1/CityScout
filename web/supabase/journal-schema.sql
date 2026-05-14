-- CityScout: journal_entries table
-- Run in the Supabase SQL Editor after schema.sql.
-- Re-running is safe (idempotent throughout).
--
-- Fields:
--   id             surrogate primary key
--   user_id        FK → auth.users, cascades on user deletion
--   itinerary_id   FK → saved_itineraries, cascades on itinerary deletion
--   destination    plain-text city name, denormalised for display
--   title          optional short entry title
--   body           the main journal text (required)
--   mood           optional mood tag from a known set
--   created_at / updated_at  timestamps; updated_at kept current by trigger
--
-- Valid mood values (enforced by Server Action, not DB constraint):
--   reflective | adventurous | relaxed | energetic | romantic | overwhelmed
--
-- Extensibility notes:
--   Add photo_urls text[], audio_url text, or stop_id uuid when those
--   features are ready. The schema is intentionally narrow for v1.

-- -------------------------------------------------------
-- Table
-- -------------------------------------------------------
create table if not exists public.journal_entries (
  id            uuid        not null default gen_random_uuid() primary key,
  user_id       uuid        not null references auth.users(id) on delete cascade,
  itinerary_id  uuid        not null references public.saved_itineraries(id) on delete cascade,
  destination   text        not null,
  title         text,
  body          text        not null,
  mood          text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- -------------------------------------------------------
-- updated_at trigger
-- -------------------------------------------------------
create or replace trigger journal_entries_moddatetime
  before update on public.journal_entries
  for each row execute procedure extensions.moddatetime(updated_at);

-- -------------------------------------------------------
-- Row Level Security
-- -------------------------------------------------------
alter table public.journal_entries enable row level security;

do $$ begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'journal_entries' and policyname = 'journal_select_own'
  ) then
    create policy "journal_select_own"
      on public.journal_entries for select
      using (auth.uid() = user_id);
  end if;
end $$;

do $$ begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'journal_entries' and policyname = 'journal_insert_own'
  ) then
    create policy "journal_insert_own"
      on public.journal_entries for insert
      with check (auth.uid() = user_id);
  end if;
end $$;

do $$ begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'journal_entries' and policyname = 'journal_update_own'
  ) then
    create policy "journal_update_own"
      on public.journal_entries for update
      using (auth.uid() = user_id);
  end if;
end $$;

do $$ begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'journal_entries' and policyname = 'journal_delete_own'
  ) then
    create policy "journal_delete_own"
      on public.journal_entries for delete
      using (auth.uid() = user_id);
  end if;
end $$;

-- -------------------------------------------------------
-- Index
-- -------------------------------------------------------
create index if not exists journal_entries_itinerary_created
  on public.journal_entries (itinerary_id, created_at desc);
