-- Members can only edit their own UPI handle.
drop policy if exists "members update for group members" on public.members;

create policy "members update own upi"
  on public.members for update
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

-- Payees confirm receipt to finalize a payment.
create or replace function public.is_payee(gid uuid, mid uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1
    from public.members m
    where m.id = mid
      and m.group_id = gid
      and m.profile_id = auth.uid()
  )
$$;

alter table public.payments add column if not exists confirmed_at timestamptz;

create policy "payments confirm by payee"
  on public.payments for update
  using (public.is_payee(group_id, to_member_id))
  with check (public.is_payee(group_id, to_member_id));