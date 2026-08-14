alter table public.workout_overviews
  add column if not exists exercise_names text[] not null default '{}'::text[];

with extracted as (
  select
    us.user_id,
    session_item.value ->> 'id' as workout_id,
    coalesce(
      array_agg(exercise_item.value ->> 'name' order by exercise_item.ordinality)
        filter (where nullif(btrim(exercise_item.value ->> 'name'), '') is not null),
      '{}'::text[]
    ) as exercise_names
  from public.user_states us
  cross join lateral jsonb_array_elements(coalesce(us.state -> 'sessions', '[]'::jsonb))
    as session_item(value)
  cross join lateral jsonb_array_elements(coalesce(session_item.value -> 'entries', '[]'::jsonb))
    with ordinality as exercise_item(value, ordinality)
  group by us.user_id, session_item.value ->> 'id'
)
update public.workout_overviews wo
set exercise_names = extracted.exercise_names
from extracted
where extracted.user_id = wo.user_id
  and extracted.workout_id = wo.id
  and cardinality(wo.exercise_names) = 0;

drop function if exists public.global_leaderboard(timestamptz);
create or replace function public.global_leaderboard(leader_period text default 'all')
returns table (
  user_id uuid,
  display_name text,
  workout_days bigint,
  workout_count bigint,
  total_sets bigint,
  total_volume_kg numeric
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  period_start timestamptz;
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if leader_period not in ('week', 'month', 'year', 'all') then
    raise exception 'Unsupported leaderboard period' using errcode = '22023';
  end if;

  period_start := case leader_period
    when 'week' then date_trunc('day', now()) - extract(dow from now()) * interval '1 day'
    when 'month' then date_trunc('month', now())
    when 'year' then date_trunc('year', now())
    else null
  end;

  return query
  select
    p.id,
    p.display_name,
    count(distinct o.workout_date) as workout_days,
    count(o.id) as workout_count,
    coalesce(sum(o.total_sets), 0)::bigint as total_sets,
    round(
      coalesce(
        sum(
          case
            when o.units = 'lbs' then o.total_volume * 0.45359237
            else o.total_volume
          end
        ),
        0
      ),
      2
    ) as total_volume_kg
  from public.profiles p
  left join public.workout_overviews o
    on o.user_id = p.id
   and (period_start is null or o.started_at >= period_start)
  group by p.id, p.display_name;
end;
$$;

revoke all on function public.global_leaderboard(text) from public;
revoke all on function public.global_leaderboard(text) from anon;
grant execute on function public.global_leaderboard(text) to authenticated;
