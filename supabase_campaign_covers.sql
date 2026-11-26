alter table public.mobile_campaigns add column cover_object_path text unique;

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('mobile-campaign-covers', 'mobile-campaign-covers', false, 5242880,
        array['image/jpeg','image/png','image/webp']);

create policy mobile_campaign_cover_upload on storage.objects for insert to authenticated
  with check (
    bucket_id = 'mobile-campaign-covers'
    and split_part(name, '/', 1) = (select auth.uid())::text
    and exists (
      select from public.mobile_profile_settings s
      where s.user_id = (select auth.uid()) and s.mode = 'fundraiser'
    )
  );

create policy mobile_campaign_cover_read on storage.objects for select to authenticated
  using (
    bucket_id = 'mobile-campaign-covers'
    and (owner_id = (select auth.uid())::text or exists (
      select from public.mobile_campaigns c where c.cover_object_path = name
    ))
  );

create policy mobile_campaign_cover_draft_delete on storage.objects for delete to authenticated
  using (
    bucket_id = 'mobile-campaign-covers'
    and owner_id = (select auth.uid())::text
    and not exists (select from public.mobile_campaigns c where c.cover_object_path = name)
  );

create function public.mobile_publish_campaign(p_title text, p_description text, p_target bigint, p_allocations jsonb, p_cover_path text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_campaign uuid;
begin
  if v_user is null then raise exception 'Sesi tidak valid'; end if;
  if not exists (select from public.mobile_profile_settings where user_id = v_user and mode = 'fundraiser')
    then raise exception 'Aktifkan mode Penggalang Dana di Profil'; end if;
  if p_cover_path is not null then
    select id into v_campaign from public.mobile_campaigns
      where cover_object_path = p_cover_path and owner_id = v_user;
    if found then return v_campaign; end if;
    if split_part(p_cover_path, '/', 1) <> v_user::text or not exists (
      select from storage.objects o where o.bucket_id = 'mobile-campaign-covers'
        and o.name = p_cover_path and o.owner_id = v_user::text
    ) then raise exception 'Foto campaign tidak tersedia'; end if;
  end if;
  if nullif(btrim(p_title), '') is null or coalesce(p_target, 0) <= 0
    or coalesce((select sum(a.amount) from jsonb_to_recordset(p_allocations) as a(amount bigint)), 0) <> p_target
    or exists (select from jsonb_to_recordset(p_allocations) as a(label text, amount bigint)
               where nullif(btrim(a.label), '') is null or coalesce(a.amount, 0) <= 0)
  then raise exception 'Judul, target, atau alokasi tidak valid'; end if;
  insert into public.mobile_campaigns(owner_id, title, description, target, cover_object_path)
    values(v_user, btrim(p_title), p_description, p_target, p_cover_path) returning id into v_campaign;
  insert into public.mobile_allocations(campaign_id, label, amount)
    select v_campaign, btrim(a.label), a.amount from jsonb_to_recordset(p_allocations) as a(label text, amount bigint);
  return v_campaign;
end $$;
revoke all on function public.mobile_publish_campaign(text,text,bigint,jsonb,text) from public, anon, authenticated;
grant execute on function public.mobile_publish_campaign(text,text,bigint,jsonb,text) to authenticated;

create or replace function public.mobile_create_campaign(p_title text, p_description text, p_target bigint, p_allocations jsonb)
returns void language plpgsql security invoker set search_path = '' as $$
begin
  perform public.mobile_publish_campaign(p_title, p_description, p_target, p_allocations, null);
end $$;

create function public.mobile_replace_campaign_cover(p_campaign uuid, p_cover_path text)
returns text language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_previous text;
begin
  select cover_object_path into v_previous from public.mobile_campaigns
    where id = p_campaign and owner_id = v_user for update;
  if not found then raise exception 'Campaign tidak dapat diubah'; end if;
  if p_cover_path is null or split_part(p_cover_path, '/', 1) <> v_user::text or not exists (
    select from storage.objects o where o.bucket_id = 'mobile-campaign-covers'
      and o.name = p_cover_path and o.owner_id = v_user::text
  ) then raise exception 'Foto campaign tidak tersedia'; end if;
  update public.mobile_campaigns set cover_object_path = p_cover_path where id = p_campaign;
  return v_previous;
end $$;
revoke all on function public.mobile_replace_campaign_cover(uuid,text) from public, anon, authenticated;
grant execute on function public.mobile_replace_campaign_cover(uuid,text) to authenticated;
