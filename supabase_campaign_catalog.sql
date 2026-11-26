alter table public.mobile_campaigns alter column owner_id drop not null;
alter table public.mobile_campaigns add column goal text, add column cover_photo integer unique;
alter table public.mobile_campaigns add constraint mobile_campaign_owner_or_catalog
  check (owner_id is not null or (goal is not null and cover_photo is not null));

insert into public.mobile_campaigns(title, target, goal, description, cover_photo) values
  ('Paket sekolah untuk 80 anak', 24000000, '80 paket perlengkapan sekolah', 'Setiap paket berisi tas, buku tulis, alat tulis, dan seragam dasar. Paket dibagikan sebelum awal semester melalui pertemuan orang tua.', 28503361),
  ('Air bersih untuk Warga Dusun', 42500000, 'Satu tandon dan tiga titik air bersama', 'Dana dialokasikan untuk tandon, pipa, dan pemasangan keran. Warga dapat mengambil air dari titik terdekat dan bergiliran memeriksa kebocoran.', 9692261),
  ('Dapur warga selepas banjir', 18000000, '600 porsi makan selama enam hari', 'Dapur warga menyiapkan 100 porsi per hari. Anggaran mencakup bahan makanan, gas memasak, dan pengantaran ke posko.', 39006612),
  ('Mangrove untuk pesisir', 32000000, '2.000 bibit mangrove dan enam bulan perawatan', 'Tim pesisir membeli bibit dari persemaian setempat, memasang penyangga, dan mengganti bibit yang mati dalam enam bulan pertama.', 35125736),
  ('Perpustakaan sore', 15000000, '300 buku dan satu ruang baca', 'Sudut balai warga dilengkapi rak rendah, buku bacaan berjenjang, dan meja bersama. Relawan mendampingi sesi membaca dua kali seminggu.', 34085957),
  ('Kebun pangan warga', 12600000, '12 bedeng sayur untuk 20 keluarga', 'Keluarga menanam sayur daun dan cabai secara bergiliran. Dana dipakai untuk benih, kompos, alat kebun, dan saluran penyiraman.', 38843811),
  ('Kursi roda pinjam pakai', 28500000, '10 kursi roda untuk peminjaman gratis', 'Pos layanan meminjamkan kursi roda kepada warga yang sedang pemulihan. Sebagian dana disisihkan untuk perawatan rem dan roda.', 20272758),
  ('Kelas menjahit pemula', 21000000, 'Empat mesin jahit dan delapan pertemuan', 'Peserta belajar mengukur, memotong pola, dan memperbaiki pakaian. Mesin dipakai bergantian, bersama kain latihan dan perlengkapan dasar.', 18181981),
  ('Listrik surya untuk ruang belajar', 37500000, 'Satu sistem surya untuk lampu dan pengisian perangkat', 'Panel, baterai, dan instalasi akan melayani ruang belajar sore. Pengelola mendapat pelatihan perawatan dasar setelah pemasangan.', 7211069),
  ('Perbaikan ruang kelas', 46000000, 'Dua ruang kelas siap digunakan', 'Pekerjaan meliputi perbaikan atap bocor, pengecatan dinding, dan penggantian meja yang rusak. Pengerjaan dijadwalkan saat libur sekolah.', 36650153)
on conflict (cover_photo) do nothing;

create or replace function public.mobile_donate(p_campaign uuid, p_amount bigint)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null or coalesce(p_amount, 0) < 5000 then raise exception 'Donasi minimum Rp5.000'; end if;
  update public.mobile_campaigns set collected = collected + p_amount
    where id = p_campaign and owner_id is distinct from v_user and status = 'active';
  if not found then raise exception 'Campaign tidak dapat menerima donasi'; end if;
  update public.mobile_profiles set balance = balance - p_amount
    where id = v_user and balance >= p_amount;
  if not found then raise exception 'Saldo tidak cukup'; end if;
  insert into public.mobile_donations(campaign_id, donor_id, amount)
    values (p_campaign, v_user, p_amount);
end $$;
