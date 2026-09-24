-- Preserve RLS while allowing the creator to complete first-time onboarding.
drop policy if exists "membership self insert" on public.workspace_members;
create policy "membership owner bootstrap" on public.workspace_members
for insert to authenticated with check (
  user_id = (select auth.uid()) and role = 'owner' and
  exists (select 1 from public.workspaces w where w.id = workspace_id and w.created_by = (select auth.uid()))
);

-- Accounts created before the Hub schema also need profiles.
insert into public.profiles (id, full_name)
select id, raw_user_meta_data->>'full_name' from auth.users
on conflict (id) do nothing;

grant usage on schema public to authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert on public.workspaces, public.workspace_members to authenticated;
grant select, insert, update, delete on public.categories, public.transactions to authenticated;

create or replace function public.create_workspace(workspace_name text, workspace_type text)
returns uuid
language plpgsql security invoker set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  workspace_id_result uuid;
begin
  if current_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if workspace_name is null or length(btrim(workspace_name)) = 0 or length(workspace_name) > 120 then
    raise exception 'Workspace name must contain 1 to 120 characters' using errcode = '22023';
  end if;
  -- Serialize retries from the same user; avoid duplicate workspaces on double submission.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(current_user_id::text, 0));
  select m.workspace_id into workspace_id_result
    from public.workspace_members m where m.user_id = current_user_id
    order by m.created_at limit 1;
  if workspace_id_result is not null then return workspace_id_result; end if;
  insert into public.workspaces(name, slug, business_type, created_by)
    values (btrim(workspace_name), 'workspace-' || gen_random_uuid()::text, workspace_type, current_user_id)
    returning id into workspace_id_result;
  insert into public.workspace_members(workspace_id, user_id, role)
    values (workspace_id_result, current_user_id, 'owner');
  return workspace_id_result;
end;
$$;
revoke all on function public.create_workspace(text, text) from public, anon;
grant execute on function public.create_workspace(text, text) to authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.is_workspace_member(uuid) from public, anon;
grant execute on function public.is_workspace_member(uuid) to authenticated;

-- Keep the RLS lookup out of the exposed API schema.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;
alter function public.is_workspace_member(uuid) set schema private;
