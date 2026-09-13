-- Users can delete transactions they are part of.

-- Payments were previously deletable by any group member ("payments delete
-- for group members"); tighten that to participants to match the update rule,
-- so unrelated members cannot remove other people's transfers.
drop policy if exists "payments delete for group members" on public.payments;

create policy "payments delete for participants"
  on public.payments for delete
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
  );

-- Expenses never had a delete policy. Splits are removed by the parent
-- expense's "on delete cascade" (runs as the table owner, bypasses RLS), so
-- only the expenses row needs the participant check.
drop policy if exists "expenses delete for participants" on public.expenses;

create policy "expenses delete for participants"
  on public.expenses for delete
  using (public.is_expense_editable(id));