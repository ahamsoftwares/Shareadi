create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  from_member_id uuid not null references public.members(id) on delete cascade,
  to_member_id uuid not null references public.members(id) on delete cascade,
  amount_cents bigint not null check (amount_cents > 0),
  note text,
  paid_at date not null default current_date,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  check (from_member_id <> to_member_id)
);

alter table public.payments enable row level security;

create policy "payments select for group members"
  on public.payments for select
  using (public.is_group_member(group_id));

create policy "payments insert for group members"
  on public.payments for insert
  with check (public.is_group_member(group_id));

create policy "payments delete for group members"
  on public.payments for delete
  using (public.is_group_member(group_id));