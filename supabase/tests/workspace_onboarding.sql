begin;
select set_config('test.owner', gen_random_uuid()::text, true);
select set_config('test.other', gen_random_uuid()::text, true);
insert into auth.users(id, email, raw_user_meta_data)
values (current_setting('test.owner')::uuid, 'hub-owner-' || current_setting('test.owner') || '@example.invalid', '{"full_name":"Hub rollback test"}'),
       (current_setting('test.other')::uuid, 'hub-other-' || current_setting('test.other') || '@example.invalid', '{}');
select set_config('request.jwt.claim.sub', current_setting('test.owner'), true);
set local role authenticated;
select set_config('test.workspace', public.create_workspace('Hub verification', 'Services')::text, true);
do $$ begin
  if (select count(*) from public.workspace_members where workspace_id=current_setting('test.workspace')::uuid) <> 1 then
    raise exception 'Owner membership missing';
  end if;
  if public.create_workspace('Retry', 'Services') <> current_setting('test.workspace')::uuid then
    raise exception 'Duplicate workspace created on retry';
  end if;
  begin
    perform public.create_workspace('   ', 'Services');
    raise exception 'Blank workspace accepted';
  exception when invalid_parameter_value then null;
  end;
end $$;
select set_config('request.jwt.claim.sub', current_setting('test.other'), true);
do $$ begin
  if exists(select 1 from public.workspaces where id=current_setting('test.workspace')::uuid) then
    raise exception 'Other user can read workspace';
  end if;
  begin
    insert into public.workspace_members(workspace_id,user_id,role)
    values(current_setting('test.workspace')::uuid,current_setting('test.other')::uuid,'owner');
    raise exception 'Other user can join workspace';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
select 'PASS: profile trigger, atomic onboarding, retries, blank names, tenant isolation and owner bootstrap RLS' as result;
rollback;
