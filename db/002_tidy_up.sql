-- OEMX Ops Platform — 002 tidy-up (safe to run more than once)
-- 1) Projections start from each person's own swing anchor date.
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
  cross join generate_series(greatest(p_from, t.anchor), least(p_through, coalesce(s.end_date - 1, p_through)), interval '1 day') d
  on conflict (staff_id, day) do nothing;
  get diagnostics n = row_count;
  insert into public.audit_log(entity, action, detail) values ('roster', 'regenerate_projections', jsonb_build_object('from', p_from, 'through', p_through, 'rows', n));
  return n;
end $$;

-- 2) Signed-out visitors can't call any helper functions.
revoke execute on function public.my_role(), public.my_staff_id(), public.is_office(), public.can_edit() from public, anon;
grant execute on function public.my_role(), public.my_staff_id(), public.is_office(), public.can_edit() to authenticated;
revoke execute on function public.regenerate_projections(date, date) from public, anon;
grant execute on function public.regenerate_projections(date, date) to authenticated;

-- 3) Split the "write" rules into insert/update/delete so reads check only one rule (faster).
do $$
declare r record;
begin
  for r in select * from (values
    ('staff','staff_write','(select public.can_edit())'),
    ('legend_codes','legend_write','(select public.can_edit())'),
    ('assets','assets_write','(select public.can_edit())'),
    ('clients','clients_write','(select public.can_edit())'),
    ('rate_items','rate_items_write','(select public.can_edit())'),
    ('roster_cells','roster_write','(select public.can_edit())'),
    ('roster_templates','templates_write','(select public.can_edit())'),
    ('profiles','profiles_manage','(select public.my_role()) = ''manager''')
  ) v(tbl, pol, expr) loop
    execute format('drop policy if exists %I on public.%I', r.pol, r.tbl);
    execute format('drop policy if exists %I on public.%I', r.pol||'_ins', r.tbl);
    execute format('drop policy if exists %I on public.%I', r.pol||'_upd', r.tbl);
    execute format('drop policy if exists %I on public.%I', r.pol||'_del', r.tbl);
    execute format('create policy %I on public.%I for insert to authenticated with check (%s)', r.pol||'_ins', r.tbl, r.expr);
    execute format('create policy %I on public.%I for update to authenticated using (%s) with check (%s)', r.pol||'_upd', r.tbl, r.expr, r.expr);
    execute format('create policy %I on public.%I for delete to authenticated using (%s)', r.pol||'_del', r.tbl, r.expr);
  end loop;
end $$;
