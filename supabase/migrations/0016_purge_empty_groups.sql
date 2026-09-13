-- When the last real (non-bot) member leaves a group, no one is left to use
-- it, so the group is deleted. The existing on delete cascade removes the
-- group's members, expenses, splits, and payments. Bots (members without a
-- profile_id) are ignored by the check because they cannot leave on their own.

drop function if exists public.leave_group(uuid);
create or replace function public.leave_group(p_gid uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_member_id uuid;
  v_is_creator boolean;
  v_new_owner uuid;
  v_humans_left boolean;
begin
  if v_uid is null then
    raise exception 'Not signed in';
  end if;

  select id into v_member_id
  from public.members
  where group_id = p_gid and profile_id = v_uid and left_at is null;

  if not found then
    raise exception 'You are not an active member of this group.';
  end if;

  select (g.created_by = v_uid) into v_is_creator
  from public.groups g
  where g.id = p_gid;

  if v_is_creator then
    select m.profile_id into v_new_owner
    from public.members m
    where m.group_id = p_gid
      and m.profile_id is not null
      and m.profile_id <> v_uid
      and m.left_at is null
    order by m.joined_at
    limit 1;

    if v_new_owner is not null then
      update public.groups
      set created_by = v_new_owner
      where id = p_gid;
    end if;
  end if;

  update public.members
  set left_at = now()
  where id = v_member_id;

  select exists (
    select 1
    from public.members
    where group_id = p_gid
      and profile_id is not null
      and left_at is null
  )
  into v_humans_left;

  if not v_humans_left then
    delete from public.groups
    where id = p_gid;
  end if;
end;
$$;

revoke execute on function public.leave_group(uuid) from public, anon;
grant execute on function public.leave_group(uuid) to authenticated;