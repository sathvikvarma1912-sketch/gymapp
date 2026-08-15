begin;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists private.user_states_backup_20260815_catalog_v4 (
  user_id uuid primary key,
  state jsonb not null,
  original_updated_at timestamptz not null,
  backed_up_at timestamptz not null default now()
);

revoke all on table private.user_states_backup_20260815_catalog_v4 from public, anon, authenticated;

do $migration$
declare
  source_rows bigint;
  backup_rows bigint;
  migrated_rows bigint;
  default_templates constant jsonb := $json$
[
  {
    "id":"default-upper","name":"Upper","icon":"💪","exercises":[
      {"id":"default-upper-01","name":"Incline smith","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0757","canonicalName":"smith incline bench press","hasVideo":true}},
      {"id":"default-upper-02","name":"Pec dec fly","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0596","canonicalName":"lever seated fly","hasVideo":true}},
      {"id":"default-upper-03","name":"Lat pulldown","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0198","canonicalName":"cable pulldown","hasVideo":true}},
      {"id":"default-upper-04","name":"Lat row","sets":1,"catalogRef":{"provider":"hasaneyldrm-github","id":"0861","canonicalName":"cable seated row","hasVideo":true}},
      {"id":"default-upper-05","name":"Upper back row","sets":1,"catalogRef":{"provider":"hasaneyldrm-github","id":"1324","canonicalName":"cable upper row","hasVideo":true}},
      {"id":"default-upper-06","name":"Lateral raise","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0334","canonicalName":"dumbbell lateral raise","hasVideo":true}},
      {"id":"default-upper-07","name":"Pushdown","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0201","canonicalName":"cable pushdown","hasVideo":true}},
      {"id":"default-upper-08","name":"Hammer curl","sets":1,"catalogRef":{"provider":"hasaneyldrm-github","id":"0313","canonicalName":"dumbbell hammer curl","hasVideo":true}},
      {"id":"default-upper-09","name":"Preacher curl","sets":1,"catalogRef":{"provider":"hasaneyldrm-github","id":"0070","canonicalName":"barbell preacher curl","hasVideo":true}},
      {"id":"default-upper-10","name":"Reverse pec dec","sets":1,"catalogRef":{"provider":"hasaneyldrm-github","id":"0602","canonicalName":"lever seated reverse fly","hasVideo":true}}
    ]
  },
  {
    "id":"default-lower","name":"Lower","icon":"🦵","exercises":[
      {"id":"default-lower-01","name":"Squat movement","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0043","canonicalName":"barbell full squat","hasVideo":true}},
      {"id":"default-lower-02","name":"Extension","sets":1,"catalogRef":{"provider":"hasaneyldrm-github","id":"0585","canonicalName":"lever leg extension","hasVideo":true}},
      {"id":"default-lower-03","name":"Abduction","sets":1,"catalogRef":{"provider":"hasaneyldrm-github","id":"0597","canonicalName":"lever seated hip abduction","hasVideo":true}},
      {"id":"default-lower-04","name":"Hamstring Curls","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0586","canonicalName":"lever lying leg curl","hasVideo":true}},
      {"id":"default-lower-05","name":"Rdl","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0085","canonicalName":"barbell romanian deadlift","hasVideo":true}},
      {"id":"default-lower-06","name":"Cable crunch","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0175","canonicalName":"cable kneeling crunch","hasVideo":true}},
      {"id":"default-lower-07","name":"Leg raises","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0620","canonicalName":"lying leg raise flat bench","hasVideo":true}},
      {"id":"default-lower-08","name":"Seated calves","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0594","canonicalName":"lever seated calf raise","hasVideo":true}}
    ]
  },
  {
    "id":"default-push","name":"Push","icon":"🔥","exercises":[
      {"id":"default-push-01","name":"Incline db press","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0314","canonicalName":"dumbbell incline bench press","hasVideo":true}},
      {"id":"default-push-02","name":"Cable flys","sets":1,"catalogRef":{"provider":"hasaneyldrm-github","id":"0227","canonicalName":"cable standing fly","hasVideo":true}},
      {"id":"default-push-03","name":"Weighted dips","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"1767","canonicalName":"weighted triceps dip on high parallel bars","hasVideo":true}},
      {"id":"default-push-04","name":"Shoulder db press","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0405","canonicalName":"dumbbell seated shoulder press","hasVideo":true}},
      {"id":"default-push-05","name":"Lateral raises","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0334","canonicalName":"dumbbell lateral raise","hasVideo":true}},
      {"id":"default-push-06","name":"Tricep cuffs pushdowns","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0201","canonicalName":"cable pushdown","hasVideo":true}},
      {"id":"default-push-07","name":"Single arm extension","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0231","canonicalName":"cable standing one arm triceps extension","hasVideo":true}}
    ]
  },
  {
    "id":"default-pull","name":"Pull","icon":"🧲","exercises":[
      {"id":"default-pull-01","name":"Weighted pullups","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0841","canonicalName":"weighted pull-up","hasVideo":true}},
      {"id":"default-pull-02","name":"Chest supported rows","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0327","canonicalName":"dumbbell incline row","hasVideo":true}},
      {"id":"default-pull-03","name":"Lat focused rows","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0861","canonicalName":"cable seated row","hasVideo":true}},
      {"id":"default-pull-04","name":"Shrugs","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0406","canonicalName":"dumbbell shrug","hasVideo":true}},
      {"id":"default-pull-05","name":"Hyperextension","sets":1,"catalogRef":{"provider":"hasaneyldrm-github","id":"0489","canonicalName":"hyperextension","hasVideo":true}},
      {"id":"default-pull-06","name":"Incline db curl","sets":1,"catalogRef":{"provider":"hasaneyldrm-github","id":"0315","canonicalName":"dumbbell incline biceps curl","hasVideo":true}},
      {"id":"default-pull-07","name":"Hammer curls","sets":1,"catalogRef":{"provider":"hasaneyldrm-github","id":"0313","canonicalName":"dumbbell hammer curl","hasVideo":true}},
      {"id":"default-pull-08","name":"Preacher curl","sets":1,"catalogRef":{"provider":"hasaneyldrm-github","id":"0070","canonicalName":"barbell preacher curl","hasVideo":true}}
    ]
  },
  {
    "id":"default-legs","name":"Legs","icon":"🦍","exercises":[
      {"id":"default-legs-01","name":"Smith machine squat","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"3281","canonicalName":"smith full squat","hasVideo":true}},
      {"id":"default-legs-02","name":"RDL","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0085","canonicalName":"barbell romanian deadlift","hasVideo":true}},
      {"id":"default-legs-03","name":"Leg press","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0739","canonicalName":"sled 45° leg press","hasVideo":true}},
      {"id":"default-legs-04","name":"Hamstring Curls","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0586","canonicalName":"lever lying leg curl","hasVideo":true}},
      {"id":"default-legs-05","name":"Adduction","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0598","canonicalName":"lever seated hip adduction","hasVideo":true}},
      {"id":"default-legs-06","name":"Abduction","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0597","canonicalName":"lever seated hip abduction","hasVideo":true}},
      {"id":"default-legs-07","name":"Decline ab crunch","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0277","canonicalName":"decline crunch","hasVideo":true}},
      {"id":"default-legs-08","name":"Leg raises","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0620","canonicalName":"lying leg raise flat bench","hasVideo":true}},
      {"id":"default-legs-09","name":"Standing calves","sets":2,"catalogRef":{"provider":"hasaneyldrm-github","id":"0605","canonicalName":"lever standing calf raise","hasVideo":true}}
    ]
  }
]
$json$::jsonb;
begin
  select count(*) into source_rows from public.user_states;

  if exists (
    select 1
    from public.user_states
    where state is null
       or jsonb_typeof(state) <> 'object'
       or jsonb_typeof(state->'templates') <> 'array'
       or jsonb_typeof(state->'sessions') <> 'array'
  ) then
    raise exception 'Catalog template migration aborted: invalid user state detected';
  end if;

  insert into private.user_states_backup_20260815_catalog_v4 (user_id, state, original_updated_at)
  select user_id, state, updated_at
  from public.user_states
  on conflict (user_id) do nothing;

  select count(*) into backup_rows
  from private.user_states_backup_20260815_catalog_v4;

  if backup_rows <> source_rows then
    raise exception 'Catalog template migration aborted: backup has % rows but source has %', backup_rows, source_rows;
  end if;

  update public.user_states
  set state = jsonb_set(
                jsonb_set(
                  jsonb_set(state, '{templates}', default_templates, true),
                  '{activeWorkout}', 'null'::jsonb, true
                ),
                '{ver}', '4'::jsonb, true
              ),
      updated_at = now();

  get diagnostics migrated_rows = row_count;
  if migrated_rows <> source_rows then
    raise exception 'Catalog template migration aborted: updated % rows but expected %', migrated_rows, source_rows;
  end if;

  if exists (
    select 1
    from public.user_states current_state
    join private.user_states_backup_20260815_catalog_v4 backup using (user_id)
    where current_state.state->'sessions' is distinct from backup.state->'sessions'
       or (current_state.state - 'templates' - 'activeWorkout' - 'ver')
          is distinct from (backup.state - 'templates' - 'activeWorkout' - 'ver')
  ) then
    raise exception 'Catalog template migration aborted: protected state changed';
  end if;

  if exists (
    select 1
    from public.user_states
    where state->>'ver' <> '4'
       or state->'activeWorkout' <> 'null'::jsonb
       or jsonb_array_length(state->'templates') <> 5
       or (
         select count(*)
         from jsonb_array_elements(state->'templates') template,
              jsonb_array_elements(template->'exercises') exercise
       ) <> 42
       or exists (
         select 1
         from jsonb_array_elements(state->'templates') template,
              jsonb_array_elements(template->'exercises') exercise
         where exercise->'catalogRef'->>'provider' <> 'hasaneyldrm-github'
            or coalesce((exercise->'catalogRef'->>'hasVideo')::boolean, false) is not true
       )
  ) then
    raise exception 'Catalog template migration aborted: migrated defaults failed validation';
  end if;
end
$migration$;

commit;
