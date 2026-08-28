-- GamoraVet 1.2: atomic pet creation + initial guardian link
-- Run after 20260828_001_secure_foundation.sql and 20260828_002_auth_profile_trigger.sql.

create or replace function public.create_pet_with_guardian(
  p_name text,
  p_species text default null,
  p_breed text default null,
  p_sex text default null,
  p_birth_date date default null,
  p_weight_kg numeric default null,
  p_photo_path text default null
)
returns public.pets
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_pet public.pets;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  if nullif(btrim(p_name), '') is null then
    raise exception 'pet name is required' using errcode = '22023';
  end if;

  if not exists (select 1 from public.profiles where id = v_user) then
    raise exception 'profile not found' using errcode = '23503';
  end if;

  insert into public.pets(name,species,breed,sex,birth_date,weight_kg,photo_path,created_by)
  values (
    btrim(p_name),
    nullif(btrim(p_species),''),
    nullif(btrim(p_breed),''),
    nullif(btrim(p_sex),''),
    p_birth_date,
    p_weight_kg,
    nullif(btrim(p_photo_path),''),
    v_user
  )
  returning * into v_pet;

  insert into public.pet_guardians(pet_id,user_id,relationship,can_manage_sharing)
  values(v_pet.id,v_user,'tutor',true);

  insert into public.audit_events(actor_user_id,pet_id,action,resource_type,resource_id,outcome,metadata)
  values(v_user,v_pet.id,'create','pet',v_pet.id,'success',jsonb_build_object('source','create_pet_with_guardian'));

  return v_pet;
end;
$$;

revoke all on function public.create_pet_with_guardian(text,text,text,text,date,numeric,text) from public;
grant execute on function public.create_pet_with_guardian(text,text,text,text,date,numeric,text) to authenticated;

comment on function public.create_pet_with_guardian(text,text,text,text,date,numeric,text)
is 'Creates a pet and its initial tutor/guardian link atomically for the authenticated user.';
