create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  description text not null,
  amount_cents bigint not null check (amount_cents > 0),
  paid_by uuid not null references public.members(id) on delete cascade,
  expense_date date not null default current_date,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.expense_splits (
  id uuid primary key default gen_random_uuid(),
  expense_id uuid not null references public.expenses(id) on delete cascade,
  member_id uuid not null references public.members(id) on delete cascade,
  amount_cents bigint not null check (amount_cents > 0)
);

alter table public.expenses enable row level security;
alter table public.expense_splits enable row level security;

create policy "expenses select for group members"
  on public.expenses for select
  using (public.is_group_member(group_id));

create policy "expenses insert for group members"
  on public.expenses for insert
  with check (public.is_group_member(group_id));

create policy "expense_splits select for group members"
  on public.expense_splits for select
  using (
    exists (
      select 1 from public.expenses e
      where e.id = expense_id and public.is_group_member(e.group_id)
    )
  );

create policy "expense_splits insert for group members"
  on public.expense_splits for insert
  with check (
    exists (
      select 1 from public.expenses e
      where e.id = expense_id and public.is_group_member(e.group_id)
    )
  );