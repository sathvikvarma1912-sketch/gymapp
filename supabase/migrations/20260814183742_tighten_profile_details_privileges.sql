revoke all on table public.profile_details from anon;
revoke all on table public.profile_details from authenticated;
grant select, insert, update on table public.profile_details to authenticated;
