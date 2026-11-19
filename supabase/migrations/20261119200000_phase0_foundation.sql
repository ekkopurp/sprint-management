-- Phase 0 foundation: enums, tables, FKs, indexes, soft-archive,
-- profiles ↔ auth.users trigger, default kanban stages on workspace create,
-- RLS helpers + policies.
-- Locked decisions: Google SSO (Auth dashboard), multi active sprints,
-- default stages To Do → … → Done (is_done only on Done), view can comment,
-- ticket types include integration, priority high|medium|low,
-- T-shirt points XS/S/M/L/XL → 2/8/21/34/55, no due date, one epic per ticket,
-- workspace_links groundwork only.

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
create type public.workspace_role as enum ('admin', 'edit', 'view');
create type public.invite_status as enum ('pending', 'accepted', 'revoked', 'expired');
create type public.ticket_priority as enum ('high', 'medium', 'low');
create type public.ticket_type as enum ('story', 'bug', 'task', 'spike', 'integration');
create type public.ticket_size as enum ('xs', 's', 'm', 'l', 'xl');
create type public.sprint_status as enum ('planned', 'active', 'completed');

-- ---------------------------------------------------------------------------
-- updated_at helper
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- T-shirt size → points (XS=2, S=8, M=21, L=34, XL=55)
-- ---------------------------------------------------------------------------
create or replace function public.ticket_size_to_points(p_size public.ticket_size)
returns smallint
language sql
immutable
as $$
  select case p_size
    when 'xs' then 2::smallint
    when 's' then 8::smallint
    when 'm' then 21::smallint
    when 'l' then 34::smallint
    when 'xl' then 55::smallint
    else null
  end;
$$;

-- ---------------------------------------------------------------------------
-- profiles (1:1 with auth.users)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_email_unique unique (email)
);

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name',
      split_part(coalesce(new.email, ''), '@', 1)
    ),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do update
    set email = excluded.email,
        display_name = coalesce(excluded.display_name, public.profiles.display_name),
        avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url),
        updated_at = now();
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- workspaces
-- ---------------------------------------------------------------------------
create table public.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null,
  created_by uuid references public.profiles (id),
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint workspaces_slug_unique unique (slug)
);

create trigger workspaces_set_updated_at
before update on public.workspaces
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- workspace_members
-- ---------------------------------------------------------------------------
create table public.workspace_members (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role public.workspace_role not null default 'view',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint workspace_members_workspace_user_unique unique (workspace_id, user_id)
);

create index workspace_members_user_id_idx on public.workspace_members (user_id);

create trigger workspace_members_set_updated_at
before update on public.workspace_members
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- invites
-- ---------------------------------------------------------------------------
create table public.invites (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  email text not null,
  role public.workspace_role not null default 'view',
  token_hash text not null,
  status public.invite_status not null default 'pending',
  invited_by uuid references public.profiles (id),
  expires_at timestamptz not null,
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index invites_pending_workspace_email_unique
  on public.invites (workspace_id, lower(email))
  where status = 'pending';

create index invites_token_hash_idx on public.invites (token_hash);

create trigger invites_set_updated_at
before update on public.invites
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- kanban_stages
-- ---------------------------------------------------------------------------
create table public.kanban_stages (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  name text not null,
  position int not null,
  is_done boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint kanban_stages_workspace_position_unique unique (workspace_id, position),
  constraint kanban_stages_workspace_name_unique unique (workspace_id, name)
);

create trigger kanban_stages_set_updated_at
before update on public.kanban_stages
for each row execute function public.set_updated_at();

-- Default stages seed helper (called on workspace create)
create or replace function public.seed_default_kanban_stages(p_workspace_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.kanban_stages (workspace_id, name, position, is_done)
  values
    (p_workspace_id, 'To Do', 1, false),
    (p_workspace_id, 'In Progress', 2, false),
    (p_workspace_id, 'Staging/QA', 3, false),
    (p_workspace_id, 'PR for Review', 4, false),
    (p_workspace_id, 'Waiting for Deploy', 5, false),
    (p_workspace_id, 'Deployed (PO to Check)', 6, false),
    (p_workspace_id, 'Done', 7, true);
end;
$$;

-- ---------------------------------------------------------------------------
-- sprints (multiple concurrent active allowed — no unique partial index)
-- ---------------------------------------------------------------------------
create table public.sprints (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  name text not null,
  goal text,
  status public.sprint_status not null default 'planned',
  starts_on date,
  ends_on date,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index sprints_workspace_status_idx on public.sprints (workspace_id, status);
create index sprints_workspace_starts_on_idx on public.sprints (workspace_id, starts_on);

create trigger sprints_set_updated_at
before update on public.sprints
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- epics
-- ---------------------------------------------------------------------------
create table public.epics (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  title text not null,
  description text,
  owner_id uuid references public.profiles (id),
  target_date date,
  color text,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index epics_workspace_archived_idx on public.epics (workspace_id, archived_at);

create trigger epics_set_updated_at
before update on public.epics
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- tickets (no due_date; at most one epic via epic_id)
-- ---------------------------------------------------------------------------
create table public.tickets (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  number int not null default 0,
  title text not null,
  description text,
  ticket_type public.ticket_type not null default 'task',
  priority public.ticket_priority not null default 'medium',
  size public.ticket_size,
  points smallint,
  stage_id uuid not null references public.kanban_stages (id),
  sprint_id uuid references public.sprints (id),
  epic_id uuid references public.epics (id),
  assignee_id uuid references public.profiles (id),
  reporter_id uuid references public.profiles (id),
  position numeric not null default 0,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tickets_workspace_number_unique unique (workspace_id, number)
);

create index tickets_workspace_sprint_stage_idx
  on public.tickets (workspace_id, sprint_id, stage_id);
create index tickets_workspace_epic_idx on public.tickets (workspace_id, epic_id);
create index tickets_assignee_id_idx on public.tickets (assignee_id);
create index tickets_stage_id_idx on public.tickets (stage_id);

create trigger tickets_set_updated_at
before update on public.tickets
for each row execute function public.set_updated_at();

create or replace function public.sync_ticket_points()
returns trigger
language plpgsql
as $$
begin
  new.points := public.ticket_size_to_points(new.size);
  return new;
end;
$$;

create trigger tickets_sync_points
before insert or update of size on public.tickets
for each row execute function public.sync_ticket_points();

-- Workspace ticket number sequence helper
create table public.workspace_ticket_counters (
  workspace_id uuid primary key references public.workspaces (id) on delete cascade,
  last_number int not null default 0
);

create or replace function public.next_ticket_number(p_workspace_id uuid)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_next int;
begin
  insert into public.workspace_ticket_counters (workspace_id, last_number)
  values (p_workspace_id, 1)
  on conflict (workspace_id) do update
    set last_number = public.workspace_ticket_counters.last_number + 1
  returning last_number into v_next;
  return v_next;
end;
$$;

create or replace function public.assign_ticket_number()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.number is null or new.number = 0 then
    new.number := public.next_ticket_number(new.workspace_id);
  end if;
  return new;
end;
$$;

create trigger tickets_assign_number
before insert on public.tickets
for each row execute function public.assign_ticket_number();

-- ---------------------------------------------------------------------------
-- tags + ticket_tags
-- ---------------------------------------------------------------------------
create table public.tags (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  name text not null,
  color text,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index tags_workspace_lower_name_unique
  on public.tags (workspace_id, lower(name));

create trigger tags_set_updated_at
before update on public.tags
for each row execute function public.set_updated_at();

create table public.ticket_tags (
  ticket_id uuid not null references public.tickets (id) on delete cascade,
  tag_id uuid not null references public.tags (id) on delete cascade,
  primary key (ticket_id, tag_id)
);

-- ---------------------------------------------------------------------------
-- comments + comment_mentions (view role can insert comments — see RLS)
-- ---------------------------------------------------------------------------
create table public.comments (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  ticket_id uuid not null references public.tickets (id) on delete cascade,
  author_id uuid not null references public.profiles (id),
  body text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index comments_ticket_id_idx on public.comments (ticket_id);
create index comments_workspace_id_idx on public.comments (workspace_id);

create trigger comments_set_updated_at
before update on public.comments
for each row execute function public.set_updated_at();

create table public.comment_mentions (
  comment_id uuid not null references public.comments (id) on delete cascade,
  mentioned_user_id uuid not null references public.profiles (id),
  primary key (comment_id, mentioned_user_id)
);

-- ---------------------------------------------------------------------------
-- workspace_links (groundwork only — no UI in v1)
-- ---------------------------------------------------------------------------
create table public.workspace_links (
  id uuid primary key default gen_random_uuid(),
  source_workspace_id uuid not null references public.workspaces (id) on delete cascade,
  target_workspace_id uuid not null references public.workspaces (id) on delete cascade,
  link_type text not null,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  constraint workspace_links_not_self check (source_workspace_id <> target_workspace_id),
  constraint workspace_links_unique unique (source_workspace_id, target_workspace_id, link_type)
);

-- ---------------------------------------------------------------------------
-- Workspace create: creator becomes admin + seed default stages
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_workspace()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.created_by is not null then
    insert into public.workspace_members (workspace_id, user_id, role)
    values (new.id, new.created_by, 'admin')
    on conflict (workspace_id, user_id) do nothing;
  end if;

  perform public.seed_default_kanban_stages(new.id);

  insert into public.workspace_ticket_counters (workspace_id, last_number)
  values (new.id, 0)
  on conflict (workspace_id) do nothing;

  return new;
end;
$$;

create trigger on_workspace_created
after insert on public.workspaces
for each row execute function public.handle_new_workspace();

-- ---------------------------------------------------------------------------
-- RLS helpers (security definer — avoid recursive policy checks)
-- ---------------------------------------------------------------------------
create or replace function public.is_workspace_member(p_workspace_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.workspace_members m
    where m.workspace_id = p_workspace_id
      and m.user_id = auth.uid()
  );
$$;

create or replace function public.workspace_role(p_workspace_id uuid)
returns public.workspace_role
language sql
stable
security definer
set search_path = public
as $$
  select m.role
  from public.workspace_members m
  where m.workspace_id = p_workspace_id
    and m.user_id = auth.uid()
  limit 1;
$$;

create or replace function public.has_workspace_role(
  p_workspace_id uuid,
  p_roles public.workspace_role[]
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.workspace_members m
    where m.workspace_id = p_workspace_id
      and m.user_id = auth.uid()
      and m.role = any (p_roles)
  );
$$;

create or replace function public.is_workspace_admin(p_workspace_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.has_workspace_role(p_workspace_id, array['admin']::public.workspace_role[]);
$$;

create or replace function public.can_edit_workspace(p_workspace_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.has_workspace_role(
    p_workspace_id,
    array['admin', 'edit']::public.workspace_role[]
  );
$$;

-- ---------------------------------------------------------------------------
-- Enable RLS
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.workspaces enable row level security;
alter table public.workspace_members enable row level security;
alter table public.invites enable row level security;
alter table public.kanban_stages enable row level security;
alter table public.sprints enable row level security;
alter table public.epics enable row level security;
alter table public.tickets enable row level security;
alter table public.workspace_ticket_counters enable row level security;
alter table public.tags enable row level security;
alter table public.ticket_tags enable row level security;
alter table public.comments enable row level security;
alter table public.comment_mentions enable row level security;
alter table public.workspace_links enable row level security;

-- ---------------------------------------------------------------------------
-- profiles policies
-- ---------------------------------------------------------------------------
create policy profiles_select_self_or_peers
  on public.profiles for select
  to authenticated
  using (
    id = auth.uid()
    or exists (
      select 1
      from public.workspace_members me
      join public.workspace_members peer
        on peer.workspace_id = me.workspace_id
      where me.user_id = auth.uid()
        and peer.user_id = profiles.id
    )
  );

create policy profiles_update_self
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Inserts come from handle_new_user trigger only (security definer).

-- ---------------------------------------------------------------------------
-- workspaces policies
-- ---------------------------------------------------------------------------
create policy workspaces_select_members
  on public.workspaces for select
  to authenticated
  using (public.is_workspace_member(id));

create policy workspaces_insert_authenticated
  on public.workspaces for insert
  to authenticated
  with check (created_by = auth.uid());

create policy workspaces_update_admin
  on public.workspaces for update
  to authenticated
  using (public.is_workspace_admin(id))
  with check (public.is_workspace_admin(id));

create policy workspaces_delete_admin
  on public.workspaces for delete
  to authenticated
  using (public.is_workspace_admin(id));

-- ---------------------------------------------------------------------------
-- workspace_members policies
-- ---------------------------------------------------------------------------
create policy workspace_members_select_members
  on public.workspace_members for select
  to authenticated
  using (public.is_workspace_member(workspace_id));

create policy workspace_members_insert_admin
  on public.workspace_members for insert
  to authenticated
  with check (public.is_workspace_admin(workspace_id));

create policy workspace_members_update_admin
  on public.workspace_members for update
  to authenticated
  using (public.is_workspace_admin(workspace_id))
  with check (public.is_workspace_admin(workspace_id));

create policy workspace_members_delete_admin
  on public.workspace_members for delete
  to authenticated
  using (public.is_workspace_admin(workspace_id));

-- ---------------------------------------------------------------------------
-- invites policies (admin only)
-- ---------------------------------------------------------------------------
create policy invites_select_admin
  on public.invites for select
  to authenticated
  using (public.is_workspace_admin(workspace_id));

create policy invites_insert_admin
  on public.invites for insert
  to authenticated
  with check (public.is_workspace_admin(workspace_id));

create policy invites_update_admin
  on public.invites for update
  to authenticated
  using (public.is_workspace_admin(workspace_id))
  with check (public.is_workspace_admin(workspace_id));

create policy invites_delete_admin
  on public.invites for delete
  to authenticated
  using (public.is_workspace_admin(workspace_id));

-- ---------------------------------------------------------------------------
-- kanban_stages policies
-- ---------------------------------------------------------------------------
create policy kanban_stages_select_members
  on public.kanban_stages for select
  to authenticated
  using (public.is_workspace_member(workspace_id));

create policy kanban_stages_insert_admin
  on public.kanban_stages for insert
  to authenticated
  with check (public.is_workspace_admin(workspace_id));

create policy kanban_stages_update_admin
  on public.kanban_stages for update
  to authenticated
  using (public.is_workspace_admin(workspace_id))
  with check (public.is_workspace_admin(workspace_id));

create policy kanban_stages_delete_admin
  on public.kanban_stages for delete
  to authenticated
  using (public.is_workspace_admin(workspace_id));

-- ---------------------------------------------------------------------------
-- sprints / epics / tags / tickets: members read; edit+ write
-- ---------------------------------------------------------------------------
create policy sprints_select_members
  on public.sprints for select
  to authenticated
  using (public.is_workspace_member(workspace_id));

create policy sprints_insert_edit
  on public.sprints for insert
  to authenticated
  with check (public.can_edit_workspace(workspace_id));

create policy sprints_update_edit
  on public.sprints for update
  to authenticated
  using (public.can_edit_workspace(workspace_id))
  with check (public.can_edit_workspace(workspace_id));

create policy sprints_delete_admin
  on public.sprints for delete
  to authenticated
  using (public.is_workspace_admin(workspace_id));

create policy epics_select_members
  on public.epics for select
  to authenticated
  using (public.is_workspace_member(workspace_id));

create policy epics_insert_edit
  on public.epics for insert
  to authenticated
  with check (public.can_edit_workspace(workspace_id));

create policy epics_update_edit
  on public.epics for update
  to authenticated
  using (public.can_edit_workspace(workspace_id))
  with check (public.can_edit_workspace(workspace_id));

create policy epics_delete_admin
  on public.epics for delete
  to authenticated
  using (public.is_workspace_admin(workspace_id));

create policy tags_select_members
  on public.tags for select
  to authenticated
  using (public.is_workspace_member(workspace_id));

create policy tags_insert_edit
  on public.tags for insert
  to authenticated
  with check (public.can_edit_workspace(workspace_id));

create policy tags_update_edit
  on public.tags for update
  to authenticated
  using (public.can_edit_workspace(workspace_id))
  with check (public.can_edit_workspace(workspace_id));

create policy tags_delete_admin
  on public.tags for delete
  to authenticated
  using (public.is_workspace_admin(workspace_id));

create policy tickets_select_members
  on public.tickets for select
  to authenticated
  using (public.is_workspace_member(workspace_id));

create policy tickets_insert_edit
  on public.tickets for insert
  to authenticated
  with check (public.can_edit_workspace(workspace_id));

create policy tickets_update_edit
  on public.tickets for update
  to authenticated
  using (public.can_edit_workspace(workspace_id))
  with check (public.can_edit_workspace(workspace_id));

create policy tickets_delete_admin
  on public.tickets for delete
  to authenticated
  using (public.is_workspace_admin(workspace_id));

-- Counters: members can read; writes via security definer functions
create policy workspace_ticket_counters_select_members
  on public.workspace_ticket_counters for select
  to authenticated
  using (public.is_workspace_member(workspace_id));

-- ticket_tags
create policy ticket_tags_select_members
  on public.ticket_tags for select
  to authenticated
  using (
    exists (
      select 1 from public.tickets t
      where t.id = ticket_tags.ticket_id
        and public.is_workspace_member(t.workspace_id)
    )
  );

create policy ticket_tags_insert_edit
  on public.ticket_tags for insert
  to authenticated
  with check (
    exists (
      select 1 from public.tickets t
      where t.id = ticket_tags.ticket_id
        and public.can_edit_workspace(t.workspace_id)
    )
  );

create policy ticket_tags_delete_edit
  on public.ticket_tags for delete
  to authenticated
  using (
    exists (
      select 1 from public.tickets t
      where t.id = ticket_tags.ticket_id
        and public.can_edit_workspace(t.workspace_id)
    )
  );

-- ---------------------------------------------------------------------------
-- comments: any member (view+) can insert; author updates; author/admin soft-delete
-- ---------------------------------------------------------------------------
create policy comments_select_members
  on public.comments for select
  to authenticated
  using (public.is_workspace_member(workspace_id));

create policy comments_insert_any_member
  on public.comments for insert
  to authenticated
  with check (
    public.is_workspace_member(workspace_id)
    and author_id = auth.uid()
  );

create policy comments_update_author
  on public.comments for update
  to authenticated
  using (
    author_id = auth.uid()
    or public.is_workspace_admin(workspace_id)
  )
  with check (
    author_id = auth.uid()
    or public.is_workspace_admin(workspace_id)
  );

create policy comments_delete_author_or_admin
  on public.comments for delete
  to authenticated
  using (
    author_id = auth.uid()
    or public.is_workspace_admin(workspace_id)
  );

create policy comment_mentions_select_members
  on public.comment_mentions for select
  to authenticated
  using (
    exists (
      select 1 from public.comments c
      where c.id = comment_mentions.comment_id
        and public.is_workspace_member(c.workspace_id)
    )
  );

create policy comment_mentions_insert_via_author
  on public.comment_mentions for insert
  to authenticated
  with check (
    exists (
      select 1 from public.comments c
      where c.id = comment_mentions.comment_id
        and c.author_id = auth.uid()
        and public.is_workspace_member(c.workspace_id)
    )
  );

create policy comment_mentions_delete_via_author_or_admin
  on public.comment_mentions for delete
  to authenticated
  using (
    exists (
      select 1 from public.comments c
      where c.id = comment_mentions.comment_id
        and (
          c.author_id = auth.uid()
          or public.is_workspace_admin(c.workspace_id)
        )
    )
  );

-- ---------------------------------------------------------------------------
-- workspace_links: members of either side can read; admin of either can manage
-- ---------------------------------------------------------------------------
create policy workspace_links_select_either_member
  on public.workspace_links for select
  to authenticated
  using (
    public.is_workspace_member(source_workspace_id)
    or public.is_workspace_member(target_workspace_id)
  );

create policy workspace_links_insert_either_admin
  on public.workspace_links for insert
  to authenticated
  with check (
    public.is_workspace_admin(source_workspace_id)
    or public.is_workspace_admin(target_workspace_id)
  );

create policy workspace_links_update_either_admin
  on public.workspace_links for update
  to authenticated
  using (
    public.is_workspace_admin(source_workspace_id)
    or public.is_workspace_admin(target_workspace_id)
  )
  with check (
    public.is_workspace_admin(source_workspace_id)
    or public.is_workspace_admin(target_workspace_id)
  );

create policy workspace_links_delete_either_admin
  on public.workspace_links for delete
  to authenticated
  using (
    public.is_workspace_admin(source_workspace_id)
    or public.is_workspace_admin(target_workspace_id)
  );

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
grant usage on schema public to authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.workspaces to authenticated;
grant select, insert, update, delete on public.workspace_members to authenticated;
grant select, insert, update, delete on public.invites to authenticated;
grant select, insert, update, delete on public.kanban_stages to authenticated;
grant select, insert, update, delete on public.sprints to authenticated;
grant select, insert, update, delete on public.epics to authenticated;
grant select, insert, update, delete on public.tickets to authenticated;
grant select on public.workspace_ticket_counters to authenticated;
grant select, insert, update, delete on public.tags to authenticated;
grant select, insert, delete on public.ticket_tags to authenticated;
grant select, insert, update, delete on public.comments to authenticated;
grant select, insert, delete on public.comment_mentions to authenticated;
grant select, insert, update, delete on public.workspace_links to authenticated;

grant execute on function public.is_workspace_member(uuid) to authenticated;
grant execute on function public.workspace_role(uuid) to authenticated;
grant execute on function public.has_workspace_role(uuid, public.workspace_role[]) to authenticated;
grant execute on function public.is_workspace_admin(uuid) to authenticated;
grant execute on function public.can_edit_workspace(uuid) to authenticated;
grant execute on function public.ticket_size_to_points(public.ticket_size) to authenticated;
-- next_ticket_number / seed_default_kanban_stages run via security definer triggers only.
