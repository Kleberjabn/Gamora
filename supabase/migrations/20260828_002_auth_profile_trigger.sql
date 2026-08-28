-- GamoraVet 1.2 auth profile trigger
-- Creates one public.profiles row for every new auth.users row.
-- Keeps role constrained to the known GamoraVet roles.

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  requested_role text;
  safe_role public.user_role;
  display_name text;
begin
  requested_role := coalesce(new.raw_user_meta_data ->> 'role', 'tutor');

  safe_role := case requested_role
    when 'clinic' then 'clinic'::public.user_role
    when 'professional' then 'professional'::public.user_role
    when 'caregiver' then 'caregiver'::public.user_role
    else 'tutor'::public.user_role
  end;

  display_name := nullif(trim(coalesce(new.raw_user_meta_data ->> 'full_name', '')), '');
  if display_name is null then
    display_name := nullif(split_part(coalesce(new.email, ''), '@', 1), '');
  end if;
  if display_name is null then
    display_name := 'Usuário GamoraVet';
  end if;

  insert into public.profiles (id, full_name, role)
  values (new.id, display_name, safe_role)
  on conflict (id) do update
    set full_name = excluded.full_name,
        role = excluded.role,
        updated_at = now();

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_auth_user();
