-- OEMX Ops Platform — 003 office logins (safe to run more than once)
-- Only emails on this invite list can create a login. Each person's role is applied automatically when they first sign in.

-- 1) New role: mobilisation officer
alter type public.app_role add value if not exists 'mobilisation';

-- 2) Invite list
create table if not exists public.office_invites (
  email text primary key check (email = lower(email)),
  display_name text not null,
  role text not null check (role in ('coordinator','manager','accounts','mobilisation')),
  invited_at timestamptz not null default now()
);
alter table public.office_invites enable row level security;
drop policy if exists invites_manage on public.office_invites;
create policy invites_manage on public.office_invites for all to authenticated
  using ((select public.my_role())::text = 'manager') with check ((select public.my_role())::text = 'manager');

insert into public.office_invites(email, display_name, role) values
  ('aherbert@oemxdiesel.com.au', 'Adam Herbert', 'manager'),
  ('jhowell@oemxdiesel.com.au', 'Joshua Howell', 'coordinator'),
  ('sclarkson@oemxdiesel.com.au', 'Stephen Clarkson', 'coordinator'),
  ('cpowers@oemxdiesel.com.au', 'Chamara Powers', 'mobilisation')
on conflict (email) do update set display_name = excluded.display_name, role = excluded.role;

-- 3) Block sign-ups from anyone not invited (employees are added in stage 2 via their staff email)
create or replace function public.guard_signup() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.office_invites where email = lower(new.email))
     and not exists (select 1 from public.staff where lower(email) = lower(new.email) and status in ('active','onboarding')) then
    raise exception 'This email is not set up for the OEMX platform. Please contact the office.';
  end if;
  return new;
end $$;
drop trigger if exists guard_signup on auth.users;
create trigger guard_signup before insert on auth.users for each row execute function public.guard_signup();

-- 4) Give each new login its profile and role
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
declare inv record; sid text;
begin
  select * into inv from public.office_invites where email = lower(new.email);
  if found then
    insert into public.profiles(user_id, role, display_name) values (new.id, inv.role::public.app_role, inv.display_name)
    on conflict (user_id) do update set role = excluded.role, display_name = excluded.display_name;
  else
    select id into sid from public.staff where lower(email) = lower(new.email) limit 1;
    insert into public.profiles(user_id, role, staff_id, display_name) values (new.id, 'employee', sid, new.email)
    on conflict (user_id) do nothing;
  end if;
  insert into public.audit_log(user_id, entity, entity_id, action) values (new.id, 'login', lower(new.email), 'created');
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();
revoke execute on function public.guard_signup(), public.handle_new_user() from public, anon, authenticated;

-- 5) Mobilisation officer: treated as office staff and can edit the roster, staff register and utes
create or replace function public.is_office() returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((select role::text in ('coordinator','manager','accounts','mobilisation') from public.profiles where user_id = auth.uid()), false)
$$;
create or replace function public.can_edit() returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((select role::text in ('coordinator','manager','mobilisation') from public.profiles where user_id = auth.uid()), false)
$$;
