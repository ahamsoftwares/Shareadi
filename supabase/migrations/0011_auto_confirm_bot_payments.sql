-- Payments to members added by name/email only (bot users, no app account)
-- should not require confirmation they can never give. Auto-confirm when the
-- payee has no linked profile, and backfill any existing pending payments to
-- such members.

create or replace function public.maybe_auto_confirm_payment()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_payee_has_profile boolean;
begin
  select (m.profile_id is not null)
  into v_payee_has_profile
  from public.members m
  where m.id = new.to_member_id;

  if new.confirmed_at is null and v_payee_has_profile = false then
    new.confirmed_at := now();
  end if;

  return new;
end;
$$;

drop trigger if exists payments_maybe_auto_confirm on public.payments;

create trigger payments_maybe_auto_confirm
  before insert on public.payments
  for each row execute procedure public.maybe_auto_confirm_payment();

-- Backfill: settle payments already recorded towards bot/pending members.
update public.payments p
set confirmed_at = now()
where p.confirmed_at is null
  and not exists (
    select 1 from public.members m
    where m.id = p.to_member_id and m.profile_id is not null
  );