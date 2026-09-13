-- Exiting a group: a member is soft-removed by setting members.left_at.
-- Their expense splits, paid expenses, and payments stay untouched, so the
-- balances of the remaining members stay exactly the same. Leaving also
-- revokes access because is_group_member() now ignores left members.

alter table public.members add column if not exists left_at timestamptz;

create or replace function public.is_group_member(gid uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1
    from public.members m
    where m.group_id = gid
      and m.profile_id = auth.uid()
      and m.left_at is null
  )
$$;

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

    if v_new_owner is null then
      raise exception 'You are the only member of this group, so you cannot leave it.';
    end if;

    update public.groups
    set created_by = v_new_owner
    where id = p_gid;
  end if;

  update public.members
  set left_at = now()
  where id = v_member_id;
end;
$$;

revoke execute on function public.leave_group(uuid) from public, anon;
grant execute on function public.leave_group(uuid) to authenticated;

-- Re-joining restores the previous membership row (matched by email) so the
-- same person does not end up twice in the group.
create or replace function public.join_group_by_code(p_code text)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_group public.groups;
  v_user_id uuid := auth.uid();
  v_user_email text;
  v_user_name text;
  v_is_member boolean;
  v_left_member_id uuid;
begin
  if v_user_id is null then
    raise exception 'Not signed in';
  end if;

  select *
  into v_group
  from public.groups
  where join_code = upper(btrim(p_code));

  if not found then
    raise exception 'That join code is not valid.';
  end if;

  select email, coalesce(nullif(name, ''), 'New member')
  into v_user_email, v_user_name
  from public.profiles
  where id = v_user_id;

  select exists(
    select 1
    from public.members
    where group_id = v_group.id
      and profile_id = v_user_id
      and left_at is null
  )
  into v_is_member;

  if v_is_member then
    raise exception 'You are already a member of this group.';
  end if;

  select id into v_left_member_id
  from public.members
  where group_id = v_group.id
    and email = v_user_email
    and left_at is not null
  limit 1;

  if v_left_member_id is not null then
    update public.members
    set profile_id = v_user_id, name = v_user_name, left_at = null
    where id = v_left_member_id;
  else
    insert into public.members (group_id, name, email, profile_id)
    values (v_group.id, v_user_name, v_user_email, v_user_id);
  end if;

  update public.invites
  set status = 'accepted'
  where group_id = v_group.id and email = v_user_email;

  return to_jsonb(v_group);
end;
$$;

revoke execute on function public.join_group_by_code(text) from public, anon;
grant execute on function public.join_group_by_code(text) to authenticated;