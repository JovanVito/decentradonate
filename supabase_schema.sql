-- Jalankan di Supabase > SQL Editor
create table profiles (id uuid primary key references auth.users on delete cascade, name text, balance bigint not null default 0 check (balance >= 0));
create table campaigns (id uuid primary key default gen_random_uuid(), owner_id uuid not null references profiles(id), title text not null, description text, target bigint not null, collected bigint not null default 0, status text not null default 'active', created_at timestamptz default now());
create table allocations (id uuid primary key default gen_random_uuid(), campaign_id uuid references campaigns(id) on delete cascade, label text not null, amount bigint not null);
create table donations (id uuid primary key default gen_random_uuid(), campaign_id uuid references campaigns(id), donor_id uuid references profiles(id), amount bigint not null check (amount > 0), created_at timestamptz default now());
create table topups (id uuid primary key default gen_random_uuid(), user_id uuid references profiles(id), amount bigint not null, created_at timestamptz default now());
create table proofs (id uuid primary key default gen_random_uuid(), campaign_id uuid references campaigns(id), user_id uuid references profiles(id), note text, image_url text not null, lat double precision not null, lng double precision not null, created_at timestamptz default now());
create table posts (id uuid primary key default gen_random_uuid(), user_id uuid references profiles(id), content text not null, created_at timestamptz default now());

-- Profil otomatis saat signup
create function handle_new_user() returns trigger language plpgsql security definer as $$
begin insert into profiles(id, name) values (new.id, new.raw_user_meta_data->>'name'); return new; end $$;
create trigger on_signup after insert on auth.users for each row execute function handle_new_user();

-- Donasi atomik: potong saldo + tambah collected
create function donate(p_campaign uuid, p_amount bigint) returns void language plpgsql security definer as $$
begin
  if (select status from campaigns where id = p_campaign) <> 'active' then raise exception 'Campaign sudah berakhir'; end if;
  update profiles set balance = balance - p_amount where id = auth.uid();
  update campaigns set collected = collected + p_amount where id = p_campaign;
  insert into donations(campaign_id, donor_id, amount) values (p_campaign, auth.uid(), p_amount);
end $$;

-- DEMO top up. Produksi: ganti dengan webhook Midtrans/Xendit (Edge Function) dan cabut akses client ke fungsi ini.
create function topup(p_amount bigint) returns void language plpgsql security definer as $$
begin
  update profiles set balance = balance + p_amount where id = auth.uid();
  insert into topups(user_id, amount) values (auth.uid(), p_amount);
end $$;

create function end_campaign(p_campaign uuid) returns void language sql security definer as $$
  update campaigns set status = 'ended' where id = p_campaign and owner_id = auth.uid();
$$;

-- RLS
alter table profiles enable row level security; alter table campaigns enable row level security;
alter table allocations enable row level security; alter table donations enable row level security;
alter table topups enable row level security; alter table proofs enable row level security; alter table posts enable row level security;
create policy "read all" on profiles for select using (true);
create policy "read all" on campaigns for select using (true);
create policy "read all" on allocations for select using (true);
create policy "read all" on donations for select using (true);
create policy "read all" on proofs for select using (true);
create policy "read all" on posts for select using (true);
create policy "own topups" on topups for select using (user_id = auth.uid());
create policy "create campaign" on campaigns for insert with check (owner_id = auth.uid());
create policy "owner allocs" on allocations for insert with check (exists (select 1 from campaigns c where c.id = campaign_id and c.owner_id = auth.uid()));
-- Bukti hanya boleh diunggah pemilik setelah campaign berakhir
create policy "owner proof" on proofs for insert with check (user_id = auth.uid() and exists (select 1 from campaigns c where c.id = campaign_id and c.owner_id = auth.uid() and c.status = 'ended'));
create policy "write post" on posts for insert with check (user_id = auth.uid());

-- Storage bucket bukti (publik agar bisa dilihat semua orang)
insert into storage.buckets(id, name, public) values ('proofs', 'proofs', true);
create policy "upload proofs" on storage.objects for insert to authenticated with check (bucket_id = 'proofs');
create policy "view proofs" on storage.objects for select using (bucket_id = 'proofs');
