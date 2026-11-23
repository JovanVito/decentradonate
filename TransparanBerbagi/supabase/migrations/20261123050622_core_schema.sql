create schema private;

create type public.app_role as enum ('donor', 'organizer', 'admin');
create type public.organizer_status as enum ('pending', 'approved', 'rejected');
create type public.campaign_status as enum ('pending', 'published', 'rejected', 'closed');
create type public.donation_status as enum ('pending', 'paid', 'expired', 'failed');
create type public.allocation_status as enum ('draft', 'published');

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  role public.app_role not null default 'donor',
  display_name text check (char_length(display_name) <= 100),
  created_at timestamptz not null default now()
);

create table public.organizer_profiles (
  user_id uuid primary key references public.profiles on delete cascade,
  organization_name text not null check (char_length(btrim(organization_name)) between 2 and 160),
  organization_type text not null,
  legal_identifier text not null,
  contact_phone text not null,
  bank_account text not null,
  document_path text not null check (split_part(document_path, '/', 1) = user_id::text),
  status public.organizer_status not null default 'pending',
  created_at timestamptz not null default now()
);

create table public.campaigns (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid not null references public.profiles,
  organizer_name text not null,
  title text not null check (char_length(btrim(title)) between 3 and 160),
  category text not null,
  story text not null,
  image_path text check (split_part(image_path, '/', 1) = organizer_id::text),
  target_amount bigint not null check (target_amount > 0),
  raised_amount bigint not null default 0 check (raised_amount >= 0),
  allocated_amount bigint not null default 0 check (allocated_amount between 0 and raised_amount),
  donor_count bigint not null default 0 check (donor_count >= 0),
  ends_at timestamptz not null,
  status public.campaign_status not null default 'pending',
  created_at timestamptz not null default now()
);

create table public.campaign_updates (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns,
  title text not null,
  body text not null,
  created_at timestamptz not null default now()
);

create table public.donations (
  id uuid primary key default gen_random_uuid(),
  donor_id uuid not null references public.profiles,
  campaign_id uuid not null references public.campaigns,
  amount bigint not null check (amount >= 10000),
  donor_name text check (char_length(donor_name) <= 100),
  anonymous boolean not null default false,
  message text check (char_length(message) <= 500),
  idempotency_key uuid not null,
  gateway_transaction_id text unique,
  status public.donation_status not null default 'pending',
  paid_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  unique (donor_id, idempotency_key),
  check ((status = 'paid') = (paid_at is not null))
);

create table public.fund_allocations (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns,
  created_by uuid not null references public.profiles,
  amount bigint not null check (amount <> 0),
  category text not null,
  description text not null,
  spent_at timestamptz not null,
  status public.allocation_status not null default 'draft',
  corrects_id uuid references public.fund_allocations,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  check (amount > 0 or corrects_id is not null),
  check ((status = 'published') = (published_at is not null))
);

create table public.allocation_proofs (
  id uuid primary key default gen_random_uuid(),
  allocation_id uuid not null references public.fund_allocations,
  photo_path text not null unique,
  invoice_path text not null unique,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  accuracy_m double precision not null check (accuracy_m between 0 and 50),
  device_captured_at timestamptz not null,
  received_at timestamptz not null default now(),
  photo_sha256 text not null check (photo_sha256 ~ '^[a-f0-9]{64}$'),
  invoice_sha256 text not null check (invoice_sha256 ~ '^[a-f0-9]{64}$'),
  address text,
  captured_in_app boolean not null default false
);

create table public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles on delete set null,
  event text not null,
  subject_id uuid not null,
  created_at timestamptz not null default now()
);

create index campaigns_public_newest on public.campaigns (created_at desc)
  where status in ('published', 'closed');
create index campaigns_owner on public.campaigns (organizer_id);
create index campaign_updates_timeline on public.campaign_updates (campaign_id, created_at desc);
create index donations_history on public.donations (donor_id, created_at desc);
create index donations_campaign on public.donations (campaign_id, donor_id) where status = 'paid';
create index allocations_timeline on public.fund_allocations (campaign_id, published_at desc);
create index allocations_correction on public.fund_allocations (corrects_id);
create index proofs_allocation on public.allocation_proofs (allocation_id);

create function private.create_profile() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

create trigger create_profile after insert on auth.users
for each row execute function private.create_profile();

create function private.sync_role() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update auth.users
  set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
    || jsonb_build_object('app_role', new.role)
  where id = new.id;
  return new;
end;
$$;

create trigger sync_role after update of role on public.profiles
for each row when (old.role is distinct from new.role)
execute function private.sync_role();

create function private.account_has_role(expected public.app_role) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = expected
      and (expected <> 'organizer' or exists (
        select 1 from public.organizer_profiles op
        where op.user_id = p.id and op.status = 'approved'
      ))
  );
$$;

create function private.record_payment() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'UPDATE' then
    if old.status = 'paid' and new is distinct from old then
      raise exception 'Settled donation is immutable';
    end if;
    if new.campaign_id <> old.campaign_id or new.amount <> old.amount
        or new.donor_id <> old.donor_id then
      raise exception 'Donation terms are immutable';
    end if;
    if old.status = new.status then
      return new;
    end if;
  end if;

  if new.status = 'paid' then
    update public.campaigns
    set raised_amount = raised_amount + new.amount
    where id = new.campaign_id;

    update public.campaigns
    set donor_count = (
      select count(distinct donor_id)
      from public.donations where campaign_id = new.campaign_id and status = 'paid'
    )
    where id = new.campaign_id;
  end if;

  insert into public.audit_logs (event, subject_id)
  values ('donation.' || new.status::text, new.id);
  return new;
end;
$$;

create trigger record_payment after insert or update on public.donations
for each row execute function private.record_payment();

create function private.publish_allocation() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  reference_amount bigint;
  corrected_amount bigint;
begin
  if tg_op <> 'INSERT' and old.status = 'published' then
    raise exception 'Published allocation is immutable';
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  if new.status <> 'published' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    raise exception 'Create a draft before publishing';
  end if;

  perform 1 from public.campaigns
  where id = new.campaign_id and organizer_id = new.created_by
    and status in ('published', 'closed')
  for update;
  if not found then
    raise exception 'Campaign is unavailable for allocation';
  end if;

  if not exists (
    select 1 from public.allocation_proofs p
    join storage.objects photo on photo.bucket_id = 'proof-photos' and photo.name = p.photo_path
    join storage.objects invoice on invoice.bucket_id = 'invoices' and invoice.name = p.invoice_path
    where p.allocation_id = new.id
      and split_part(p.photo_path, '/', 1) = new.created_by::text
      and split_part(p.invoice_path, '/', 1) = new.created_by::text
      and split_part(p.photo_path, '/', 2) = new.id::text
      and split_part(p.invoice_path, '/', 2) = new.id::text
  ) then
    raise exception 'Photo and invoice are required';
  end if;

  if new.corrects_id is not null then
    select amount into reference_amount from public.fund_allocations
    where id = new.corrects_id and campaign_id = new.campaign_id
      and status = 'published' and corrects_id is null;
    if not found then
      raise exception 'Invalid allocation reference';
    end if;
    select coalesce(sum(amount), 0) into corrected_amount
    from public.fund_allocations
    where corrects_id = new.corrects_id and status = 'published';
    if reference_amount + corrected_amount + new.amount < 0 then
      raise exception 'Correction exceeds original allocation';
    end if;
  end if;

  update public.campaigns
  set allocated_amount = allocated_amount + new.amount
  where id = new.campaign_id
    and allocated_amount + new.amount between 0 and raised_amount;
  if not found then
    raise exception 'Allocation exceeds available funds';
  end if;

  new.published_at := now();
  insert into public.audit_logs (actor_id, event, subject_id)
  values (new.created_by, 'allocation.published', new.id);
  return new;
end;
$$;

create trigger publish_allocation before insert or update or delete on public.fund_allocations
for each row execute function private.publish_allocation();

create function private.check_proof_write() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  target_id uuid;
  target_status public.allocation_status;
begin
  if tg_op = 'UPDATE' then
    raise exception 'Replace proof with a new row while the allocation is a draft';
  end if;
  target_id := case when tg_op = 'DELETE' then old.allocation_id else new.allocation_id end;
  select status into target_status
  from public.fund_allocations where id = target_id for update;
  if not found or target_status <> 'draft' then
    raise exception 'Proof requires a draft allocation';
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create trigger check_proof_write before insert or update or delete on public.allocation_proofs
for each row execute function private.check_proof_write();

create view public.campaign_fund_summary with (security_invoker = true) as
select id as campaign_id, raised_amount, allocated_amount,
  raised_amount - allocated_amount as balance_amount, donor_count
from public.campaigns;

alter table public.profiles enable row level security;
alter table public.organizer_profiles enable row level security;
alter table public.campaigns enable row level security;
alter table public.campaign_updates enable row level security;
alter table public.donations enable row level security;
alter table public.fund_allocations enable row level security;
alter table public.allocation_proofs enable row level security;
alter table public.audit_logs enable row level security;

revoke all on all functions in schema private from public, anon, authenticated;
grant usage on schema private to authenticated;
grant execute on function private.account_has_role(public.app_role) to authenticated;
