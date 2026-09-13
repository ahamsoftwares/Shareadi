-- Users can edit transactions they are part of: expenses they paid, split
-- on, or created; payments where they are the payer or payee (or creator).

-- Expensive edit check: group member AND (created OR paid by user's member
-- row OR has a split row for the user's member row).
create or replace function public.is_expense_editable(eid uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1
    from public.expenses e
    where e.id = eid
      and public.is_group_member(e.group_id)
      and (
        e.created_by = auth.uid()
        or exists (
          select 1 from public.members pm
          where pm.id = e.paid_by and pm.profile_id = auth.uid()
        )
        or exists (
          select 1
          from public.expense_splits es
          join public.members sm on sm.id = es.member_id
          where es.expense_id = e.id and sm.profile_id = auth.uid()
        )
      )
  )
$$;

create policy "expenses update for participants"
  on public.expenses for update
  using (public.is_expense_editable(id))
  with check (public.is_group_member(group_id));

-- Replacing splits on edit requires deleting the old rows and inserting the
-- new ones, so both the update and delete paths use the same participant
-- check on the parent expense.
create policy "expense_splits update for participants"
  on public.expense_splits for update
  using (public.is_expense_editable(expense_id))
  with check (
    exists (
      select 1 from public.expenses e
      where e.id = expense_id and public.is_group_member(e.group_id)
    )
  );

create policy "expense_splits delete for participants"
  on public.expense_splits for delete
  using (public.is_expense_editable(expense_id));

-- Payments: the user may update payments they created or where their member
-- row is either the payer or the payee.
create policy "payments update for participants"
  on public.payments for update
  using (
    public.is_group_member(group_id)
    and (
      created_by = auth.uid()
      or exists (
        select 1 from public.members m
        where (m.id = from_member_id or m.id = to_member_id)
          and m.profile_id = auth.uid()
      )
    )
  )
  with check (public.is_group_member(group_id));