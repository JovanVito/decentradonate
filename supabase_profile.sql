create table public.mobile_profile_settings (
  user_id uuid primary key references public.mobile_profiles(id) on delete cascade,
  phone text check (phone is null or phone ~ '^[+]?[0-9]{7,15}$'),
  mode text not null default 'donor' check (mode in ('donor', 'fundraiser'))
);
alter table public.mobile_profile_settings enable row level security;
revoke all on public.mobile_profile_settings from public, anon, authenticated;
grant select, insert on public.mobile_profile_settings to authenticated;
grant update (phone, mode) on public.mobile_profile_settings to authenticated;
create policy mobile_settings_read on public.mobile_profile_settings for select to authenticated
  using (user_id = (select auth.uid()));
create policy mobile_settings_insert on public.mobile_profile_settings for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy mobile_settings_update on public.mobile_profile_settings for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
grant update (name) on public.mobile_profiles to authenticated;
create policy mobile_profile_edit on public.mobile_profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
insert into public.mobile_profile_settings(user_id, mode)
select distinct owner_id, 'fundraiser' from public.mobile_campaigns on conflict do nothing;

create function public.mobile_save_profile(p_name text, p_phone text, p_mode text)
returns void language plpgsql security invoker set search_path = '' as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'Sesi tidak valid'; end if;
  if length(p_name) > 80 then raise exception 'Nama terlalu panjang'; end if;
  update public.mobile_profiles set name = nullif(btrim(p_name), '') where id = v_user;
  if not found then raise exception 'Profil tidak ditemukan'; end if;
  insert into public.mobile_profile_settings(user_id, phone, mode)
    values(v_user, nullif(btrim(p_phone), ''), p_mode)
    on conflict(user_id) do update set phone = excluded.phone, mode = excluded.mode;
end $$;
revoke all on function public.mobile_save_profile(text,text,text) from public, anon, authenticated;
grant execute on function public.mobile_save_profile(text,text,text) to authenticated;

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('mobile-avatars', 'mobile-avatars', false, 5242880, array['image/jpeg','image/png','image/webp']);
create policy mobile_avatar_owner on storage.objects for all to authenticated
  using (bucket_id = 'mobile-avatars' and name = ((select auth.uid())::text || '/avatar'))
  with check (bucket_id = 'mobile-avatars' and name = ((select auth.uid())::text || '/avatar'));

create or replace function public.mobile_create_campaign(p_title text, p_description text, p_target bigint, p_allocations jsonb)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_campaign uuid;
begin
  if v_user is null then raise exception 'Sesi tidak valid'; end if;
  if not exists (select from public.mobile_profile_settings where user_id = v_user and mode = 'fundraiser')
    then raise exception 'Aktifkan mode Penggalang Dana di Profil'; end if;
  if nullif(btrim(p_title), '') is null or coalesce(p_target, 0) <= 0
    or coalesce((select sum(a.amount) from jsonb_to_recordset(p_allocations) as a(amount bigint)), 0) <> p_target
    or exists (select from jsonb_to_recordset(p_allocations) as a(label text, amount bigint)
               where nullif(btrim(a.label), '') is null or coalesce(a.amount, 0) <= 0)
  then raise exception 'Judul, target, atau alokasi tidak valid'; end if;
  insert into public.mobile_campaigns(owner_id, title, description, target)
    values(v_user, btrim(p_title), p_description, p_target) returning id into v_campaign;
  insert into public.mobile_allocations(campaign_id, label, amount)
    select v_campaign, btrim(a.label), a.amount from jsonb_to_recordset(p_allocations) as a(label text, amount bigint);
end $$;
