revoke all on public.profiles, public.organizer_profiles, public.campaigns,
  public.campaign_updates, public.donations, public.fund_allocations,
  public.allocation_proofs, public.audit_logs, public.campaign_fund_summary
from public, anon, authenticated;

grant select on public.campaigns, public.campaign_updates, public.fund_allocations,
  public.allocation_proofs, public.campaign_fund_summary to anon, authenticated;
grant select on public.profiles, public.organizer_profiles,
  public.donations, public.audit_logs to authenticated;
grant update (display_name) on public.profiles to authenticated;
grant insert (user_id, organization_name, organization_type, legal_identifier,
  contact_phone, bank_account, document_path) on public.organizer_profiles to authenticated;
grant insert (id, organizer_id, organizer_name, title, category, story, image_path,
  target_amount, ends_at) on public.campaigns to authenticated;
grant update (title, category, story, image_path, target_amount, ends_at)
  on public.campaigns to authenticated;
grant insert (campaign_id, title, body) on public.campaign_updates to authenticated;
grant insert (id, campaign_id, created_by, amount, category, description, spent_at, corrects_id)
  on public.fund_allocations to authenticated;
grant update (amount, category, description, spent_at, corrects_id)
  on public.fund_allocations to authenticated;

grant all on public.profiles, public.organizer_profiles, public.campaigns,
  public.campaign_updates, public.donations, public.fund_allocations,
  public.allocation_proofs, public.audit_logs to service_role;
grant select on public.campaign_fund_summary to service_role;

create policy profiles_read on public.profiles for select to authenticated
using (id = (select auth.uid()) or (select private.account_has_role('admin')));
create policy profiles_update_name on public.profiles for update to authenticated
using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy organizer_applications_read on public.organizer_profiles for select to authenticated
using (user_id = (select auth.uid()) or (select private.account_has_role('admin')));
create policy organizer_applications_submit on public.organizer_profiles for insert to authenticated
with check (user_id = (select auth.uid()) and status = 'pending');

create policy campaigns_public_read on public.campaigns for select to anon, authenticated
using (status in ('published', 'closed'));
create policy campaigns_staff_read on public.campaigns for select to authenticated
using (
  (organizer_id = (select auth.uid()) and (select private.account_has_role('organizer')))
  or (select private.account_has_role('admin'))
);
create policy campaigns_create on public.campaigns for insert to authenticated
with check (
  organizer_id = (select auth.uid()) and (select private.account_has_role('organizer'))
  and status = 'pending' and organizer_name = (
    select organization_name from public.organizer_profiles where user_id = (select auth.uid())
  )
);
create policy campaigns_edit_pending on public.campaigns for update to authenticated
using (
  organizer_id = (select auth.uid()) and status = 'pending'
  and (select private.account_has_role('organizer'))
)
with check (
  organizer_id = (select auth.uid()) and status = 'pending'
  and (select private.account_has_role('organizer'))
);

create policy updates_read on public.campaign_updates for select to anon, authenticated
using (exists (select 1 from public.campaigns c where c.id = campaign_id));
create policy updates_create on public.campaign_updates for insert to authenticated
with check (
  (select private.account_has_role('organizer')) and exists (
    select 1 from public.campaigns c
    where c.id = campaign_id and c.organizer_id = (select auth.uid())
      and c.status in ('published', 'closed')
  )
);

create policy donations_read_own on public.donations for select to authenticated
using (donor_id = (select auth.uid()));

create policy allocations_public_read on public.fund_allocations for select to anon, authenticated
using (
  status = 'published' and exists (
    select 1 from public.campaigns c
    where c.id = campaign_id and c.status in ('published', 'closed')
  )
);
create policy allocations_staff_read on public.fund_allocations for select to authenticated
using (
  (created_by = (select auth.uid()) and (select private.account_has_role('organizer')))
  or (select private.account_has_role('admin'))
);
create policy allocations_create on public.fund_allocations for insert to authenticated
with check (
  status = 'draft' and created_by = (select auth.uid())
  and (select private.account_has_role('organizer'))
  and exists (
    select 1 from public.campaigns c
    where c.id = campaign_id and c.organizer_id = (select auth.uid())
      and c.status in ('published', 'closed')
  )
);
create policy allocations_edit_draft on public.fund_allocations for update to authenticated
using (
  status = 'draft' and created_by = (select auth.uid())
  and (select private.account_has_role('organizer'))
)
with check (
  status = 'draft' and created_by = (select auth.uid())
  and (select private.account_has_role('organizer'))
);

create policy proofs_read on public.allocation_proofs for select to anon, authenticated
using (exists (select 1 from public.fund_allocations a where a.id = allocation_id));
create policy audit_read on public.audit_logs for select to authenticated
using ((select private.account_has_role('admin')));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('campaign-images', 'campaign-images', false, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('proof-photos', 'proof-photos', false, 10485760, array['image/jpeg', 'image/png', 'image/webp']),
  ('invoices', 'invoices', false, 10485760, array['image/jpeg', 'image/png', 'application/pdf']),
  ('organizer-docs', 'organizer-docs', false, 10485760, array['image/jpeg', 'image/png', 'application/pdf']);

create policy storage_organizer_documents_upload on storage.objects for insert to authenticated
with check (
  bucket_id = 'organizer-docs' and split_part(name, '/', 1) = (select auth.uid())::text
);
create policy storage_organizer_documents_read on storage.objects for select to authenticated
using (
  bucket_id = 'organizer-docs' and (
    split_part(name, '/', 1) = (select auth.uid())::text
    or (select private.account_has_role('admin'))
  )
);

create policy storage_campaign_upload on storage.objects for insert to authenticated
with check (
  bucket_id = 'campaign-images' and split_part(name, '/', 1) = (select auth.uid())::text
  and (select private.account_has_role('organizer'))
);
create policy storage_campaign_read on storage.objects for select to anon, authenticated
using (
  bucket_id = 'campaign-images' and exists (
    select 1 from public.campaigns c where c.image_path = name
  )
);
create policy storage_own_campaign_media_read on storage.objects for select to authenticated
using (
  bucket_id = 'campaign-images' and split_part(name, '/', 1) = (select auth.uid())::text
  and (select private.account_has_role('organizer'))
);

create policy storage_allocation_upload on storage.objects for insert to authenticated
with check (
  bucket_id in ('proof-photos', 'invoices') and (select private.account_has_role('organizer'))
  and split_part(name, '/', 1) = (select auth.uid())::text
  and exists (
    select 1 from public.fund_allocations a
    where a.id::text = split_part(name, '/', 2)
      and a.created_by = (select auth.uid()) and a.status = 'draft'
  )
);
create policy storage_allocation_read on storage.objects for select to anon, authenticated
using (
  bucket_id in ('proof-photos', 'invoices') and exists (
    select 1 from public.allocation_proofs p
    where (bucket_id = 'proof-photos' and p.photo_path = name)
      or (bucket_id = 'invoices' and p.invoice_path = name)
  )
);
create policy storage_own_allocation_media_read on storage.objects for select to authenticated
using (
  bucket_id in ('proof-photos', 'invoices') and (select private.account_has_role('organizer'))
  and split_part(name, '/', 1) = (select auth.uid())::text
);

create function private.review_organizer(target_user uuid, decision public.organizer_status)
returns void language plpgsql set search_path = '' as $$
begin
  if decision not in ('approved', 'rejected') then
    raise exception 'Invalid review decision';
  end if;
  update public.organizer_profiles set status = decision where user_id = target_user;
  if not found then
    raise exception 'Application not found';
  end if;
  update public.profiles
  set role = case decision when 'approved' then 'organizer'::public.app_role
    else 'donor'::public.app_role end
  where id = target_user and role <> 'admin';
  insert into public.audit_logs (actor_id, event, subject_id)
  values (auth.uid(), 'organizer.' || decision::text, target_user);
end;
$$;

create function private.review_campaign(target_campaign uuid, decision public.campaign_status)
returns void language plpgsql set search_path = '' as $$
begin
  update public.campaigns set status = decision
  where id = target_campaign and (
    (status = 'pending' and decision in ('published', 'rejected'))
    or (status = 'published' and decision = 'closed')
  );
  if not found then
    raise exception 'Invalid campaign transition';
  end if;
  insert into public.audit_logs (actor_id, event, subject_id)
  values (auth.uid(), 'campaign.' || decision::text, target_campaign);
end;
$$;

revoke all on function private.review_organizer(uuid, public.organizer_status)
  from public, anon, authenticated;
revoke all on function private.review_campaign(uuid, public.campaign_status)
  from public, anon, authenticated;

alter publication supabase_realtime add table public.donations;
