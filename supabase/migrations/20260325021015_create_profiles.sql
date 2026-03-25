-- Migration: Create profiles table with RLS and triggers
-- Created: 2026-03-25

-- Create profiles table
create table public.profiles (
  id uuid references auth.users (id) on delete cascade primary key,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Comments
comment on table public.profiles is 'User profile data, one row per auth.users entry';
comment on column public.profiles.id is 'References auth.users(id), serves as primary key';
comment on column public.profiles.display_name is 'User-facing display name';
comment on column public.profiles.avatar_url is 'URL to the user avatar image';
comment on column public.profiles.created_at is 'Timestamp when the profile was created';
comment on column public.profiles.updated_at is 'Timestamp when the profile was last updated';

-- Enable RLS
alter table public.profiles enable row level security;

-- RLS policies
create policy "Users can read own profile"
  on public.profiles for select
  to authenticated
  using ((select auth.uid()) = id);

create policy "Users can update own profile"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Reusable trigger function: set updated_at on row update
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

comment on function public.handle_updated_at is 'Sets updated_at to now() before update on any table';

-- Trigger function: create profile on new auth user
-- SECURITY DEFINER: needs to insert into public.profiles from auth schema trigger
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.raw_user_meta_data ->> 'display_name');
  return new;
end;
$$;

comment on function public.handle_new_user is 'Creates a profile row when a new user signs up via auth.users';

-- Triggers
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

create trigger on_profiles_updated
  before update on public.profiles
  for each row
  execute function public.handle_updated_at();
