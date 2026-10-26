-- OEMX Ops Platform — 001 core schema
-- Run once in Supabase: project oemx-ops → SQL Editor → New query → paste → Run.
-- Creates staff, logins/roles, legend, assets, clients, rate items, roster, swing templates, audit log,
-- with row-level security (office sees all; employees see only their own record and roster;
-- only coordinator/manager can edit).

create type public.app_role as enum ('coordinator','manager','accounts','employee');

create table public.staff (
  id text primary key,
  first_name text not null,
  last_name text not null,
  email text,
  phone text,
  trade text,
  roster_pattern text,
  employment_type text,
  ute text,
  company text,
  site text,
  home_base text,
  status text not null default 'active' check (status in ('active','onboarding','subcontractor','left')),
  monday_id text unique,
  monday_status text,
  start_date date,
  end_date date,
  notes text,
  roster_note text,
  exclude_from_payroll boolean not null default false,
  xero_employee_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role public.app_role not null default 'employee',
  staff_id text references public.staff(id) on delete set null,
  display_name text,
  created_at timestamptz not null default now()
);
create index profiles_staff_idx on public.profiles(staff_id);

create table public.legend_codes (
  code text primary key,
  description text not null,
  company text,
  category text not null,
  colour text,
  sort_order int
);

create table public.assets (
  id text primary key,
  name text not null unique,
  type text not null default 'Ute',
  notes text
);

create table public.clients (
  id text primary key,
  name text not null,
  xero_contact_id text,
  legend_company text,
  item_prefix text,
  active boolean not null default true,
  last_invoiced date
);

create table public.rate_items (
  code text primary key,
  description text not null,
  unit text not null default 'hr',
  price numeric(10,2) not null,
  min_billed numeric(10,2),
  max_billed numeric(10,2),
  client_prefix text not null default 'GENERIC',
  source text
);

create table public.roster_cells (
  staff_id text not null references public.staff(id) on delete cascade,
  day date not null,
  code text,
  hours text,
  km text,
  asset text,
  source text not null default 'confirmed' check (source in ('actual','plan','proj','confirmed')),
  updated_by uuid default auth.uid(),
  updated_at timestamptz not null default now(),
  primary key (staff_id, day)
);
create index roster_cells_day_idx on public.roster_cells(day);

create table public.roster_templates (
  staff_id text primary key references public.staff(id) on delete cascade,
  anchor date not null,
  template text[] not null,
  note text,
  updated_at timestamptz not null default now()
);

create table public.audit_log (
  id bigint generated always as identity primary key,
  at timestamptz not null default now(),
  user_id uuid default auth.uid(),
  entity text not null,
  entity_id text,
  action text not null,
  detail jsonb
);
create index audit_log_entity_idx on public.audit_log(entity, entity_id);

create or replace function public.touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at := now(); return new; end $$;
create trigger staff_touch before update on public.staff for each row execute function public.touch_updated_at();
create trigger roster_cells_touch before update on public.roster_cells for each row execute function public.touch_updated_at();
create trigger roster_templates_touch before update on public.roster_templates for each row execute function public.touch_updated_at();

create or replace function public.my_role() returns public.app_role
language sql stable security definer set search_path = '' as $$
  select role from public.profiles where user_id = auth.uid()
$$;
create or replace function public.my_staff_id() returns text
language sql stable security definer set search_path = '' as $$
  select staff_id from public.profiles where user_id = auth.uid()
$$;
create or replace function public.is_office() returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((select role in ('coordinator','manager','accounts') from public.profiles where user_id = auth.uid()), false)
$$;
create or replace function public.can_edit() returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((select role in ('coordinator','manager') from public.profiles where user_id = auth.uid()), false)
$$;
revoke execute on function public.my_role(), public.my_staff_id(), public.is_office(), public.can_edit() from anon;

alter table public.staff enable row level security;
alter table public.profiles enable row level security;
alter table public.legend_codes enable row level security;
alter table public.assets enable row level security;
alter table public.clients enable row level security;
alter table public.rate_items enable row level security;
alter table public.roster_cells enable row level security;
alter table public.roster_templates enable row level security;
alter table public.audit_log enable row level security;

create policy staff_read on public.staff for select to authenticated
  using ((select public.is_office()) or id = (select public.my_staff_id()));
create policy staff_write on public.staff for all to authenticated
  using ((select public.can_edit())) with check ((select public.can_edit()));

create policy profiles_read on public.profiles for select to authenticated
  using (user_id = (select auth.uid()) or (select public.is_office()));
create policy profiles_manage on public.profiles for all to authenticated
  using ((select public.my_role()) = 'manager') with check ((select public.my_role()) = 'manager');

create policy legend_read on public.legend_codes for select to authenticated using (true);
create policy legend_write on public.legend_codes for all to authenticated
  using ((select public.can_edit())) with check ((select public.can_edit()));

create policy assets_read on public.assets for select to authenticated using ((select public.is_office()));
create policy assets_write on public.assets for all to authenticated using ((select public.can_edit())) with check ((select public.can_edit()));
create policy clients_read on public.clients for select to authenticated using ((select public.is_office()));
create policy clients_write on public.clients for all to authenticated using ((select public.can_edit())) with check ((select public.can_edit()));
create policy rate_items_read on public.rate_items for select to authenticated using ((select public.is_office()));
create policy rate_items_write on public.rate_items for all to authenticated using ((select public.can_edit())) with check ((select public.can_edit()));

create policy roster_read on public.roster_cells for select to authenticated
  using ((select public.is_office()) or staff_id = (select public.my_staff_id()));
create policy roster_write on public.roster_cells for all to authenticated
  using ((select public.can_edit())) with check ((select public.can_edit()));

create policy templates_read on public.roster_templates for select to authenticated using ((select public.is_office()));
create policy templates_write on public.roster_templates for all to authenticated using ((select public.can_edit())) with check ((select public.can_edit()));

create policy audit_read on public.audit_log for select to authenticated using ((select public.is_office()));

create or replace function public.regenerate_projections(p_from date default current_date, p_through date default date '2027-06-30')
returns integer language plpgsql security definer set search_path = '' as $$
declare n integer;
begin
  if not coalesce((select role in ('coordinator','manager') from public.profiles where user_id = auth.uid()), auth.uid() is null) then
    raise exception 'Only the coordinator or manager can regenerate projections';
  end if;
  delete from public.roster_cells where source = 'proj' and day >= p_from and day <= p_through;
  insert into public.roster_cells (staff_id, day, code, source, updated_by)
  select t.staff_id, d::date,
         t.template[1 + (((d::date - t.anchor) % array_length(t.template,1)) + array_length(t.template,1)) % array_length(t.template,1)],
         'proj', auth.uid()
  from public.roster_templates t
  join public.staff s on s.id = t.staff_id and s.status in ('active','subcontractor')
  cross join generate_series(p_from, least(p_through, coalesce(s.end_date - 1, p_through)), interval '1 day') d
  on conflict (staff_id, day) do nothing;
  get diagnostics n = row_count;
  insert into public.audit_log(entity, action, detail) values ('roster', 'regenerate_projections', jsonb_build_object('from', p_from, 'through', p_through, 'rows', n));
  return n;
end $$;
revoke execute on function public.regenerate_projections(date, date) from anon, public;
grant execute on function public.regenerate_projections(date, date) to authenticated;
