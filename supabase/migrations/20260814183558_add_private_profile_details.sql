create table if not exists public.profile_details (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  first_name text not null check (char_length(btrim(first_name)) between 1 and 60),
  last_name text not null check (char_length(btrim(last_name)) between 1 and 60),
  age smallint not null check (age between 13 and 120),
  gender text not null check (gender in ('male', 'female', 'non_binary', 'other', 'prefer_not_to_say')),
  weight_kg numeric(6,2) not null check (weight_kg between 20 and 500),
  height_cm numeric(5,2) not null check (height_cm between 80 and 300),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profile_details enable row level security;

revoke all on table public.profile_details from anon;
revoke all on table public.profile_details from authenticated;
grant select, insert, update on table public.profile_details to authenticated;

drop policy if exists "owners read profile details" on public.profile_details;
create policy "owners read profile details" on public.profile_details
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "owners insert profile details" on public.profile_details;
create policy "owners insert profile details" on public.profile_details
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "owners update profile details" on public.profile_details;
create policy "owners update profile details" on public.profile_details
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
