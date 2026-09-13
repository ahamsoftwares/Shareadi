create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text not null default 'travel' check (type in ('travel', 'house')),
  currency text not null default 'INR',
  join_code text not null unique,
  created_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  name text not null,
  email text,
  profile_id uuid references public.profiles(id) on delete set null,
  joined_at timestamptz not null default now()
);

create unique index members_group_email_unique
  on public.members (group_id, email) where email is not null;

create table if not exists public.invites (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  email text not null,
  status text not null default 'pending' check (status in ('pending', 'accepted')),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (group_id, email)
);

create or replace function public.is_group_member(gid uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1
    from public.members m
    where m.group_id = gid
      and m.profile_id = auth.uid()
  )
$$;

alter table public.groups enable row level security;
alter table public.members enable row level security;
alter table public.invites enable row level security;

create policy "groups select for members or creator"
  on public.groups for select
  using (created_by = auth.uid() or public.is_group_member(id));

create policy "groups insert by creator"
  on public.groups for insert
  with check (created_by = auth.uid());

create policy "groups update by creator"
  on public.groups for update
  using (created_by = auth.uid());

create policy "members select for group members"
  on public.members for select
  using (public.is_group_member(group_id));

create policy "members insert for group members or self"
  on public.members for insert
  with check (profile_id = auth.uid() or public.is_group_member(group_id));

create policy "members delete for group members"
  on public.members for delete
  using (public.is_group_member(group_id));

create policy "invites select for group members or invitee"
  on public.invites for select
  using (
    email = (select email from public.profiles where id = auth.uid())
    or public.is_group_member(group_id)
  );

create policy "invites insert for group members"
  on public.invites for insert
  with check (public.is_group_member(group_id));

create policy "invites update by invitee"
  on public.invites for update
  using (email = (select email from public.profiles where id = auth.uid()));