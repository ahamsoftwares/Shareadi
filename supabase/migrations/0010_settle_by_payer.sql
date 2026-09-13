-- Only the payer can record a settle-up payment. Replaces the earlier
-- "any group member may record any payment" insert policy with one that
-- requires the paying member to be the current user's member row.
create or replace function public.is_member_user(mid uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.members m
    where m.id = mid and m.profile_id = auth.uid()
  )
$$;

drop policy if exists "payments insert for group members" on public.payments;

create policy "payments insert by payer"
  on public.payments for insert
  with check (
    public.is_group_member(group_id)
    and public.is_member_user(from_member_id)
    and exists (
      select 1 from public.members m2
      where m2.id = to_member_id and m2.group_id = group_id
    )
  );