-- CityScout: saved_itineraries table
-- Run this in the Supabase SQL Editor for your project.
-- Re-running is safe (uses IF NOT EXISTS / DO blocks).

-- -------------------------------------------------------
-- Table
-- -------------------------------------------------------

create table if not exists public.saved_itineraries (
  id          uuid        primary key default gen_random_uuid(),
  user_id     uuid        not null references auth.users(id) on delete cascade,
  destination text        not null,
  title       text        not null,
  summary     text,
  payload     jsonb       not null,
  created_at  timestamptz not null default now()
);

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
