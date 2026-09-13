alter table public.members add column if not exists upi_id text;

create policy "members update for group members"
  on public.members for update
  using (public.is_group_member(group_id))
  with check (public.is_group_member(group_id));