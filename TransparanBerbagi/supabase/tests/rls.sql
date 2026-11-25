begin;

do $$
begin
  if (select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relrowsecurity and c.relname in (
        'profiles', 'organizer_profiles', 'campaigns', 'campaign_updates',
        'donations', 'fund_allocations', 'allocation_proofs', 'audit_logs'
      )) <> 8 then
    raise exception 'Expected RLS on all eight application tables';
  end if;
end;
$$;

insert into auth.users (id, email)
values ('a1000000-0000-4000-8000-000000000003', 'other@example.test');

set local role authenticated;
set local request.jwt.claim.sub = 'a1000000-0000-4000-8000-000000000003';

do $$
begin
  if exists (select 1 from public.donations) then
    raise exception 'Cross-account donation leak';
  end if;
  if exists (select 1 from public.organizer_profiles) then
    raise exception 'Organizer legal data leaked';
  end if;
  if exists (select 1 from public.fund_allocations) then
    raise exception 'Draft allocation leaked';
  end if;
  if not exists (select 1 from public.campaigns where title = 'Buku untuk taman baca') then
    raise exception 'Published campaign should be readable';
  end if;
  begin
    update public.profiles set role = 'organizer' where id = auth.uid();
    raise exception 'Unauthorized role change succeeded';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.donations set status = 'failed';
    raise exception 'Unauthorized payment update succeeded';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.fund_allocations (campaign_id, created_by, amount, category, description, spent_at)
    values ('a2000000-0000-4000-8000-000000000001', auth.uid(), 10000, 'Buku', 'Test', now());
    raise exception 'Unapproved account created an allocation';
  exception when insufficient_privilege then null;
  end;
end;
$$;

set local request.jwt.claim.sub = 'a1000000-0000-4000-8000-000000000002';
do $$
begin
  if (select count(*) from public.donations) <> 1 then
    raise exception 'Donor cannot see own donation';
  end if;
end;
$$;

set local request.jwt.claim.sub = 'a1000000-0000-4000-8000-000000000001';
do $$
begin
  if (select count(*) from public.fund_allocations) <> 1 then
    raise exception 'Approved organizer cannot see own draft';
  end if;
end;
$$;

reset role;
select private.review_organizer('a1000000-0000-4000-8000-000000000001', 'rejected');
set local role authenticated;
set local request.jwt.claim.app_metadata = '{"app_role":"organizer"}';
do $$
begin
  if exists (select 1 from public.fund_allocations) then
    raise exception 'Revoked organizer retained draft access';
  end if;
end;
$$;
reset role;
select private.review_organizer('a1000000-0000-4000-8000-000000000001', 'approved');
set local request.jwt.claim.sub = '';
set local request.jwt.claim.app_metadata = '';

-- Transaction-only Storage metadata fixtures. No files are added to a real bucket.
insert into storage.objects (bucket_id, name) values
  ('proof-photos', 'a1000000-0000-4000-8000-000000000001/a4000000-0000-4000-8000-000000000001/test.jpg'),
  ('invoices', 'a1000000-0000-4000-8000-000000000001/a4000000-0000-4000-8000-000000000001/test.pdf');

insert into public.allocation_proofs (
  allocation_id, photo_path, invoice_path, latitude, longitude, accuracy_m,
  device_captured_at, photo_sha256, invoice_sha256
) values (
  'a4000000-0000-4000-8000-000000000001',
  'a1000000-0000-4000-8000-000000000001/a4000000-0000-4000-8000-000000000001/test.jpg',
  'a1000000-0000-4000-8000-000000000001/a4000000-0000-4000-8000-000000000001/test.pdf',
  -6.2, 106.8, 12, now(), repeat('a', 64), repeat('b', 64)
);

do $$
begin
  begin
    update public.fund_allocations set status = 'published', amount = 250001
    where id = 'a4000000-0000-4000-8000-000000000001';
    raise exception 'Overspending was accepted';
  exception when raise_exception then
    if sqlerrm <> 'Allocation exceeds available funds' then
      raise;
    end if;
  end;

  update public.fund_allocations set status = 'published'
  where id = 'a4000000-0000-4000-8000-000000000001';

  if (select balance_amount from public.campaign_fund_summary
      where campaign_id = 'a2000000-0000-4000-8000-000000000001') <> 125000 then
    raise exception 'Wrong balance after publication';
  end if;

  begin
    delete from public.fund_allocations where id = 'a4000000-0000-4000-8000-000000000001';
    raise exception 'Published allocation was deleted';
  exception when raise_exception then
    if sqlerrm <> 'Published allocation is immutable' then
      raise;
    end if;
  end;
end;
$$;

set local role anon;
do $$
begin
  if not exists (select 1 from public.allocation_proofs
                 where allocation_id = 'a4000000-0000-4000-8000-000000000001') then
    raise exception 'Published proof must be visible to the public';
  end if;
end;
$$;

rollback;
