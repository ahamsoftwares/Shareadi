-- Icons for groups and expenses. Icon values are Material icon keys
-- (e.g. 'groups', 'restaurant_menu'); unknown keys render as the default.

alter table public.groups
  add column if not exists icon text not null default 'groups';

alter table public.expenses
  add column if not exists icon text not null default 'receipt_long';

-- Edit a group's name and/or icon. Only the creator may do it.
drop function if exists public.update_group(uuid, text, text);
create or replace function public.update_group(gid uuid, new_name text, new_icon text default null)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not signed in';
  end if;

  if new_name is not null and btrim(new_name) = '' then
    raise exception 'Name cannot be empty';
  end if;

  if not exists (
    select 1 from public.groups g
    where g.id = gid and g.created_by = auth.uid()
  ) then
    raise exception 'Only the group creator can edit the group';
  end if;

  update public.groups
  set name = coalesce(nullif(btrim(new_name), ''), name),
      icon = coalesce(new_icon, icon)
  where id = gid;
end;
$$;

revoke execute on function public.update_group(uuid, text, text) from public, anon;
grant execute on function public.update_group(uuid, text, text) to authenticated;