-- GamoraVet 1.2 authenticated Data API grants
-- RLS remains the authorization boundary. These GRANTs only allow the
-- authenticated PostgREST role to reach the tables/functions so RLS can run.

begin;

-- Schema access for authenticated mobile users.
grant usage on schema public to authenticated;

-- Tutor-owned resources. Row-level security policies created in migration 001
-- continue to decide which rows each authenticated user may read/change.
grant select, insert, update on table public.profiles to authenticated;
grant select, insert, update on table public.pets to authenticated;
grant select, insert, delete on table public.pet_guardians to authenticated;
grant select on table public.audit_events to authenticated;
grant select, insert, update, delete on table public.privacy_requests to authenticated;

-- Sharing/organization resources needed by the existing RLS model.
grant select, insert, update on table public.organizations to authenticated;
grant select on table public.organization_members to authenticated;
grant select, insert, update on table public.sharing_grants to authenticated;
grant select, insert on table public.consent_events to authenticated;

-- Explicitly expose only the intended helper/RPC functions to signed-in users.
grant execute on function public.is_pet_guardian(uuid) to authenticated;
grant execute on function public.can_manage_pet_sharing(uuid) to authenticated;
grant execute on function public.is_org_member(uuid) to authenticated;
grant execute on function public.has_active_grant(uuid,uuid,text) to authenticated;
grant execute on function public.create_pet_with_guardian(text,text,text,text,date,numeric,text) to authenticated;

commit;
