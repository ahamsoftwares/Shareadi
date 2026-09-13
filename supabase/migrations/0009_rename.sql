-- Rename a member's display name within a group. Any group member may do it.
-- A function (not a plain row policy) is used so only the `name` column can be
-- changed; a row-level policy would also allow editing upi_id/email of others.
create or replace function public.rename_member(mid uuid, new_name text)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not signed in';
  end if;

  if btrim(new_name) = '' then
    raise exception 'Name cannot be empty';
  end if;

  if not exists (
    select 1
    from public.members m
    where m.id = mid
      and public.is_group_member(m.group_id)
  ) then
    raise exception 'Member not found in one of your groups';
  end if;

  update public.members
  set name = btrim(new_name)
  where id = mid;
end;
$$;

revoke execute on function public.rename_member(uuid, text) from public, anon;
grant execute on function public.rename_member(uuid, text) to authenticated;

-- Rename a group. Only the creator may do it.
create or replace function public.rename_group(gid uuid, new_name text)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not signed in';
  end if;

  if btrim(new_name) = '' then
    raise exception 'Name cannot be empty';
  end if;

  if not exists (
    select 1 from public.groups g
    where g.id = gid and g.created_by = auth.uid()
  ) then
    raise exception 'Only the group creator can rename the group';
  end if;

  update public.groups
  set name = btrim(new_name)
  where id = gid;
end;
$$;

revoke execute on function public.rename_group(uuid, text) from public, anon;
grant execute on function public.rename_group(uuid, text) to authenticated;