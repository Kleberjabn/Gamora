-- GamoraVet 1.2 medication administration RPC
-- Records a caregiver/tutor action without trusting pet/user identifiers from the client.

begin;

create or replace function public.record_medication_administration(
  p_medication_id uuid,
  p_status text default 'administered',
  p_scheduled_for timestamptz default null,
  p_notes text default null
)
returns public.medication_administrations
language plpgsql
security invoker
set search_path=public
as $$
declare
  v_pet_id uuid;
  v_row public.medication_administrations;
begin
  if auth.uid() is null then
    raise exception 'authentication required' using errcode='28000';
  end if;

  if p_status not in ('administered','snoozed','skipped','missed') then
    raise exception 'invalid administration status' using errcode='22023';
  end if;

  select m.pet_id into v_pet_id
  from public.medications m
  where m.id=p_medication_id and m.is_active=true;

  if v_pet_id is null then
    raise exception 'medication not found' using errcode='P0002';
  end if;

  if not public.is_pet_guardian(v_pet_id) then
    raise exception 'pet access denied' using errcode='42501';
  end if;

  insert into public.medication_administrations(
    medication_id,pet_id,status,scheduled_for,recorded_by,notes
  ) values (
    p_medication_id,v_pet_id,p_status,p_scheduled_for,auth.uid(),nullif(btrim(p_notes),'')
  ) returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.record_medication_administration(uuid,text,timestamptz,text) from public;
grant execute on function public.record_medication_administration(uuid,text,timestamptz,text) to authenticated;

commit;
