-- GamoraVet 1.2 medications foundation
-- Tutor medication plans + recorded administrations, protected by pet RLS.

begin;

create table public.medications (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  name text not null check (length(btrim(name)) > 0),
  dose_text text,
  schedule_time time,
  is_active boolean not null default true,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.medication_administrations (
  id uuid primary key default gen_random_uuid(),
  medication_id uuid not null references public.medications(id) on delete cascade,
  pet_id uuid not null references public.pets(id) on delete cascade,
  status text not null check (status in ('administered','snoozed','skipped','missed')),
  scheduled_for timestamptz,
  recorded_at timestamptz not null default now(),
  recorded_by uuid not null references public.profiles(id),
  notes text,
  created_at timestamptz not null default now()
);

create index medications_pet_id_idx on public.medications(pet_id);
create index medication_administrations_pet_id_idx on public.medication_administrations(pet_id);
create index medication_administrations_medication_id_idx on public.medication_administrations(medication_id);

alter table public.medications enable row level security;
alter table public.medication_administrations enable row level security;

grant select, insert, update, delete on table public.medications to authenticated;
grant select, insert, update, delete on table public.medication_administrations to authenticated;

create policy medications_guardian_read on public.medications for select using (public.is_pet_guardian(pet_id));
create policy medications_guardian_insert on public.medications for insert with check (created_by=auth.uid() and public.is_pet_guardian(pet_id));
create policy medications_guardian_update on public.medications for update using (public.is_pet_guardian(pet_id)) with check (public.is_pet_guardian(pet_id));
create policy medications_guardian_delete on public.medications for delete using (public.is_pet_guardian(pet_id));

create policy med_admin_guardian_read on public.medication_administrations for select using (public.is_pet_guardian(pet_id));
create policy med_admin_guardian_insert on public.medication_administrations for insert with check (recorded_by=auth.uid() and public.is_pet_guardian(pet_id));
create policy med_admin_guardian_update on public.medication_administrations for update using (recorded_by=auth.uid() and public.is_pet_guardian(pet_id)) with check (recorded_by=auth.uid() and public.is_pet_guardian(pet_id));
create policy med_admin_guardian_delete on public.medication_administrations for delete using (recorded_by=auth.uid() and public.is_pet_guardian(pet_id));

create or replace function public.create_medication_for_pet(
  p_pet_id uuid,
  p_name text,
  p_dose_text text default null,
  p_schedule_time time default null
)
returns public.medications
language plpgsql
security invoker
set search_path=public
as $$
declare v_med public.medications;
begin
  if auth.uid() is null then raise exception 'authentication required' using errcode='28000'; end if;
  if not public.is_pet_guardian(p_pet_id) then raise exception 'pet access denied' using errcode='42501'; end if;
  insert into public.medications(pet_id,name,dose_text,schedule_time,created_by)
  values(p_pet_id,btrim(p_name),nullif(btrim(p_dose_text),''),p_schedule_time,auth.uid())
  returning * into v_med;
  return v_med;
end;
$$;

revoke all on function public.create_medication_for_pet(uuid,text,text,time) from public;
grant execute on function public.create_medication_for_pet(uuid,text,text,time) to authenticated;

commit;
