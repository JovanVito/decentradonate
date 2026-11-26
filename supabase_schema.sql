-- Donasi Transparan mobile MVP, isolated from the existing application tables.
create table public.mobile_profiles (id uuid primary key references auth.users on delete cascade, name text, balance bigint not null default 0 check (balance >= 0));
create table public.mobile_campaigns (id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.mobile_profiles(id), title text not null, description text, target bigint not null check (target > 0), collected bigint not null default 0, status text not null default 'active', created_at timestamptz default now());
create table public.mobile_allocations (id uuid primary key default gen_random_uuid(), campaign_id uuid references public.mobile_campaigns(id) on delete cascade, label text not null, amount bigint not null check (amount > 0));
create table public.mobile_donations (id uuid primary key default gen_random_uuid(), campaign_id uuid references public.mobile_campaigns(id), donor_id uuid references public.mobile_profiles(id), amount bigint not null check (amount > 0), created_at timestamptz default now());
create table public.mobile_topups (id uuid primary key default gen_random_uuid(), user_id uuid references public.mobile_profiles(id), amount bigint not null, created_at timestamptz default now());
create table public.mobile_proofs (id uuid primary key default gen_random_uuid(), campaign_id uuid references public.mobile_campaigns(id), user_id uuid references public.mobile_profiles(id), note text, image_url text not null, lat double precision not null, lng double precision not null, created_at timestamptz default now());
create table public.mobile_posts (id uuid primary key default gen_random_uuid(), user_id uuid references public.mobile_profiles(id), content text not null, created_at timestamptz default now());


create schema if not exists private;
create function private.mobile_profile_on_signup() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.mobile_profiles(id, name)
  values (new.id, new.raw_user_meta_data->>'name');
  return new;
end $$;
revoke all on function private.mobile_profile_on_signup() from public, anon, authenticated;
create trigger mobile_profile_on_signup after insert on auth.users
for each row execute function private.mobile_profile_on_signup();
insert into public.mobile_profiles(id, name)
select id, raw_user_meta_data->>'name' from auth.users on conflict (id) do nothing;

create function public.mobile_create_campaign(p_title text, p_description text, p_target bigint, p_allocations jsonb)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_campaign uuid;
begin
  if v_user is null then raise exception 'Sesi tidak valid'; end if;
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

create function public.mobile_donate(p_campaign uuid, p_amount bigint)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null or coalesce(p_amount, 0) <= 0 then raise exception 'Nominal donasi tidak valid'; end if;
  update public.mobile_campaigns set collected = collected + p_amount
    where id = p_campaign and owner_id <> v_user and status = 'active';
  if not found then raise exception 'Campaign tidak dapat menerima donasi'; end if;
  update public.mobile_profiles set balance = balance - p_amount
    where id = v_user and balance >= p_amount;
  if not found then raise exception 'Saldo tidak cukup'; end if;
  insert into public.mobile_donations(campaign_id, donor_id, amount)
    values (p_campaign, v_user, p_amount);
end $$;

-- Test credits only. No payment or withdrawal integration.
create function public.mobile_demo_topup(p_amount bigint)
returns void language plpgsql security definer set search_path = '' as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null or p_amount is null or p_amount not in (10000, 50000, 100000, 500000)
    then raise exception 'Nominal saldo demo tidak valid'; end if;
  update public.mobile_profiles set balance = balance + p_amount
    where id = v_user and balance <= 1000000 - p_amount;
  if not found then raise exception 'Saldo demo maksimal Rp 1.000.000'; end if;
  insert into public.mobile_topups(user_id, amount) values(v_user, p_amount);
end $$;

create function public.mobile_balance() returns bigint
language sql stable security definer set search_path = '' as $$
  select balance from public.mobile_profiles where id = auth.uid()
$$;

create function public.mobile_end_campaign(p_campaign uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.mobile_campaigns set status = 'ended'
  where id = p_campaign and owner_id = auth.uid() and status = 'active';
  if not found then raise exception 'Campaign tidak dapat diakhiri'; end if;
end $$;

revoke all on function public.mobile_create_campaign(text,text,bigint,jsonb) from public, anon, authenticated;
grant execute on function public.mobile_create_campaign(text,text,bigint,jsonb) to authenticated;
revoke all on function public.mobile_donate(uuid,bigint) from public, anon, authenticated;
grant execute on function public.mobile_donate(uuid,bigint) to authenticated;
revoke all on function public.mobile_demo_topup(bigint) from public, anon, authenticated;
grant execute on function public.mobile_demo_topup(bigint) to authenticated;
revoke all on function public.mobile_balance() from public, anon, authenticated;
grant execute on function public.mobile_balance() to authenticated;
revoke all on function public.mobile_end_campaign(uuid) from public, anon, authenticated;
grant execute on function public.mobile_end_campaign(uuid) to authenticated;
alter table public.mobile_profiles enable row level security;
revoke all on public.mobile_profiles from public, anon, authenticated;
grant select (id, name) on public.mobile_profiles to authenticated;
create policy read_mobile_profiles on public.mobile_profiles for select to authenticated using (true);
alter table public.mobile_campaigns enable row level security;
revoke all on public.mobile_campaigns from public, anon, authenticated;
grant select on public.mobile_campaigns to authenticated;
create policy read_mobile_campaigns on public.mobile_campaigns for select to authenticated using (true);
alter table public.mobile_allocations enable row level security;
revoke all on public.mobile_allocations from public, anon, authenticated;
grant select on public.mobile_allocations to authenticated;
create policy read_mobile_allocations on public.mobile_allocations for select to authenticated using (true);
alter table public.mobile_donations enable row level security;
revoke all on public.mobile_donations from public, anon, authenticated;
grant select on public.mobile_donations to authenticated;
create policy read_mobile_donations on public.mobile_donations for select to authenticated using (true);
alter table public.mobile_topups enable row level security;
revoke all on public.mobile_topups from public, anon, authenticated;
grant select on public.mobile_topups to authenticated;
create policy read_mobile_topups on public.mobile_topups for select to authenticated using (user_id = (select auth.uid()));
alter table public.mobile_proofs enable row level security;
revoke all on public.mobile_proofs from public, anon, authenticated;
grant select on public.mobile_proofs to authenticated;
create policy read_mobile_proofs on public.mobile_proofs for select to authenticated using (true);
alter table public.mobile_posts enable row level security;
revoke all on public.mobile_posts from public, anon, authenticated;
grant select on public.mobile_posts to authenticated;
create policy read_mobile_posts on public.mobile_posts for select to authenticated using (true);
grant insert on public.mobile_posts, public.mobile_proofs to authenticated;
create policy insert_mobile_post on public.mobile_posts for insert to authenticated
  with check (user_id = (select auth.uid()) and length(btrim(content)) between 1 and 2000);
create policy insert_mobile_proof on public.mobile_proofs for insert to authenticated
  with check (user_id = (select auth.uid()) and lat between -90 and 90 and lng between -180 and 180
    and exists (select from public.mobile_campaigns c
                where c.id = campaign_id and c.owner_id = (select auth.uid()) and c.status = 'ended')
    and exists (select from storage.objects o where o.bucket_id = 'mobile-proofs'
                and o.name = image_url and split_part(o.name, '/', 1) = campaign_id::text));
create index on public.mobile_campaigns(owner_id);
create index on public.mobile_allocations(campaign_id);
create index on public.mobile_donations(campaign_id, created_at desc);
create index on public.mobile_donations(donor_id, created_at desc);
create index on public.mobile_topups(user_id, created_at desc);
create index on public.mobile_proofs(campaign_id, created_at);
create index on public.mobile_proofs(user_id);
create index on public.mobile_posts(user_id);

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('mobile-proofs', 'mobile-proofs', false, 10485760, array['image/jpeg']);
create policy mobile_proof_upload on storage.objects for insert to authenticated
  with check (bucket_id = 'mobile-proofs' and exists (
    select from public.mobile_campaigns c where c.id::text = split_part(name, '/', 1)
      and c.owner_id = (select auth.uid()) and c.status = 'ended'));
create policy mobile_proof_read on storage.objects for select to authenticated
  using (bucket_id = 'mobile-proofs');
create policy mobile_proof_cleanup on storage.objects for delete to authenticated
  using (bucket_id = 'mobile-proofs' and owner_id = (select auth.uid())::text and not exists (
    select from public.mobile_proofs p where p.image_url = name));
