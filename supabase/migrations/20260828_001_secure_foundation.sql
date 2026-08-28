-- GamoraVet 1.2 secure backend foundation
-- PostgreSQL / Supabase-compatible migration
-- Security model: auth.users + RLS + explicit pet/organization grants.

create extension if not exists pgcrypto;

create type public.user_role as enum ('tutor','clinic','professional','caregiver');
create type public.member_role as enum ('admin','veterinarian','reception','inventory');
create type public.grant_status as enum ('active','revoked','expired');
create type public.privacy_request_type as enum ('access','correction','export','deletion','revocation','other');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role public.user_role not null default 'tutor',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.pets (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  species text,
  breed text,
  sex text,
  birth_date date,
  weight_kg numeric(8,2),
  photo_path text,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.pet_guardians (
  pet_id uuid not null references public.pets(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  relationship text not null default 'tutor',
  can_manage_sharing boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (pet_id,user_id)
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  legal_name text not null,
  trade_name text,
  document_number text,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organization_members (
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.member_role not null,
  professional_registry text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (organization_id,user_id)
);

create table public.sharing_grants (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  granted_by uuid not null references public.profiles(id),
  purpose text not null,
  categories text[] not null check (cardinality(categories) > 0),
  status public.grant_status not null default 'active',
  notice_version text not null,
  legal_basis text not null,
  granted_at timestamptz not null default now(),
  expires_at timestamptz,
  revoked_at timestamptz,
  revoked_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.consent_events (
  id uuid primary key default gen_random_uuid(),
  grant_id uuid not null references public.sharing_grants(id) on delete cascade,
  actor_user_id uuid not null references public.profiles(id),
  event_type text not null check (event_type in ('granted','changed','revoked')),
  categories text[] not null,
  purpose text not null,
  notice_version text not null,
  legal_basis text not null,
  occurred_at timestamptz not null default now()
);

create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references public.profiles(id),
  organization_id uuid references public.organizations(id),
  pet_id uuid references public.pets(id),
  action text not null,
  resource_type text not null,
  resource_id uuid,
  outcome text not null default 'success',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.privacy_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  request_type public.privacy_request_type not null,
  status text not null default 'open',
  details text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create or replace function public.is_pet_guardian(target_pet uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.pet_guardians pg where pg.pet_id=target_pet and pg.user_id=auth.uid());
$$;

create or replace function public.can_manage_pet_sharing(target_pet uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.pet_guardians pg where pg.pet_id=target_pet and pg.user_id=auth.uid() and pg.can_manage_sharing=true);
$$;

create or replace function public.is_org_member(target_org uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.organization_members om where om.organization_id=target_org and om.user_id=auth.uid() and om.is_active=true);
$$;

create or replace function public.has_active_grant(target_pet uuid,target_org uuid,category text)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(
    select 1 from public.sharing_grants g
    where g.pet_id=target_pet
      and g.organization_id=target_org
      and g.status='active'
      and (g.expires_at is null or g.expires_at>now())
      and category=any(g.categories)
  );
$$;

alter table public.profiles enable row level security;
alter table public.pets enable row level security;
alter table public.pet_guardians enable row level security;
alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.sharing_grants enable row level security;
alter table public.consent_events enable row level security;
alter table public.audit_events enable row level security;
alter table public.privacy_requests enable row level security;

create policy profiles_self_read on public.profiles for select using (id=auth.uid());
create policy profiles_self_update on public.profiles for update using (id=auth.uid()) with check (id=auth.uid());

create policy pets_guardian_read on public.pets for select using (public.is_pet_guardian(id));
create policy pets_creator_insert on public.pets for insert with check (created_by=auth.uid());
create policy pets_guardian_update on public.pets for update using (public.is_pet_guardian(id));

create policy pet_guardians_self_or_manager_read on public.pet_guardians for select using (user_id=auth.uid() or public.can_manage_pet_sharing(pet_id));
create policy pet_guardians_manager_insert on public.pet_guardians for insert with check (public.can_manage_pet_sharing(pet_id) or user_id=auth.uid());
create policy pet_guardians_manager_delete on public.pet_guardians for delete using (public.can_manage_pet_sharing(pet_id));

create policy organizations_member_read on public.organizations for select using (public.is_org_member(id));
create policy organizations_creator_insert on public.organizations for insert with check (created_by=auth.uid());

create policy organization_members_member_read on public.organization_members for select using (user_id=auth.uid() or public.is_org_member(organization_id));

create policy grants_guardian_read on public.sharing_grants for select using (public.is_pet_guardian(pet_id));
create policy grants_org_read on public.sharing_grants for select using (public.is_org_member(organization_id));
create policy grants_manager_insert on public.sharing_grants for insert with check (granted_by=auth.uid() and public.can_manage_pet_sharing(pet_id));
create policy grants_manager_update on public.sharing_grants for update using (public.can_manage_pet_sharing(pet_id));

create policy consent_guardian_read on public.consent_events for select using (exists(select 1 from public.sharing_grants g where g.id=grant_id and public.is_pet_guardian(g.pet_id)));
create policy consent_actor_insert on public.consent_events for insert with check (actor_user_id=auth.uid());

create policy audit_self_or_guardian_read on public.audit_events for select using (actor_user_id=auth.uid() or (pet_id is not null and public.is_pet_guardian(pet_id)));

create policy privacy_self_all on public.privacy_requests for all using (user_id=auth.uid()) with check (user_id=auth.uid());

-- Do not expose service-role credentials to the mobile app.
-- Server-side functions or trusted backend code should write privileged audit events.
