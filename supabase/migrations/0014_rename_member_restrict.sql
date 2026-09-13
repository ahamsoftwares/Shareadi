-- Renaming is only allowed for the member's own profile, or for bot members
-- (added by name/email only, no linked profile). Real users cannot have their
-- name changed by other people.
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

  if not exists (
    select 1 from public.members m
    where m.id = mid
      and (m.profile_id is null or m.profile_id = auth.uid())
  ) then
    raise exception 'You can only rename yourself or members added by name';
  end if;

  update public.members
  set name = btrim(new_name)
  where id = mid;
end;
$$;