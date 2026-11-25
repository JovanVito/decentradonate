-- Local database fixtures. Create a separate test account for end-to-end OTP.
insert into auth.users (id, email, aud, role, email_confirmed_at)
values
  ('a1000000-0000-4000-8000-000000000001', 'organizer@example.test', 'authenticated', 'authenticated', now()),
  ('a1000000-0000-4000-8000-000000000002', 'donor@example.test', 'authenticated', 'authenticated', now());

insert into public.organizer_profiles (
  user_id, organization_name, organization_type, legal_identifier,
  contact_phone, bank_account, document_path
) values (
  'a1000000-0000-4000-8000-000000000001', 'Komunitas Taman Belajar', 'Komunitas',
  'DEMO', 'DEMO', 'DEMO', 'a1000000-0000-4000-8000-000000000001/demo.pdf'
);

select private.review_organizer('a1000000-0000-4000-8000-000000000001', 'approved');

insert into public.campaigns (
  id, organizer_id, organizer_name, title, category, story, target_amount, ends_at
) values (
  'a2000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001',
  'Komunitas Taman Belajar', 'Buku untuk taman baca', 'Pendidikan',
  'Bantu menyediakan buku bacaan anak untuk taman baca komunitas.',
  5000000, now() + interval '30 days'
);

select private.review_campaign('a2000000-0000-4000-8000-000000000001', 'published');

insert into public.donations (
  donor_id, campaign_id, amount, idempotency_key, anonymous, status, paid_at
) values (
  'a1000000-0000-4000-8000-000000000002', 'a2000000-0000-4000-8000-000000000001',
  250000, 'a3000000-0000-4000-8000-000000000001', true, 'paid', now()
);

insert into public.fund_allocations (
  id, campaign_id, created_by, amount, category, description, spent_at
) values (
  'a4000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001',
  'a1000000-0000-4000-8000-000000000001', 125000, 'Buku',
  'Draf pengadaan buku bacaan anak', now()
);
