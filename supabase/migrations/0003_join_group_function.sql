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
    where group_id = v_group.id and profile_id = v_user_id
  )
  into v_is_member;

  if v_is_member then
    raise exception 'You are already a member of this group.';
  end if;

  insert into public.members (group_id, name, email, profile_id)
  values (v_group.id, v_user_name, v_user_email, v_user_id);

  update public.invites
  set status = 'accepted'
  where group_id = v_group.id
    and email = v_user_email;

  return to_jsonb(v_group);
end;
$$;