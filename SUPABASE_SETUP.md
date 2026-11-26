# Setup Supabase

Dokumen ini menjadi instruksi untuk agent yang menyiapkan project Supabase nyata.

## Prasyarat

- Project Supabase.
- Akses Supabase Dashboard sebagai owner atau developer.
- Flutter SDK terpasang.
- Repository sudah berisi `supabase_schema.sql`.

## 1. Buat project

1. Buka Supabase Dashboard.
2. Pilih `New project`.
3. Pilih organization.
4. Isi nama project dan password database.
5. Simpan region project.
6. Tunggu project aktif.

Jangan menyimpan password database di repository.

## 2. Jalankan schema

1. Buka `SQL Editor`.
2. Buat query baru.
3. Salin seluruh isi `supabase_schema.sql`.
4. Jalankan query.
5. Pastikan tidak ada error.
6. Buka `Table Editor` dan pastikan tabel berikut tersedia:

```text
profiles
campaigns
allocations
donations
topups
proofs
posts
```

7. Buka `Database > Functions` dan pastikan fungsi berikut tersedia:

```text
handle_new_user
 donate
 topup
 end_campaign
```

Hapus spasi awal pada nama `donate` jika muncul karena tampilan, nama fungsi harus `donate`.

## 3. Periksa Storage

Pastikan bucket berikut tersedia:

```text
proofs
```

Bucket saat ini dibuat publik oleh schema agar URL foto dapat dibaca pengguna. Sebelum produksi, review ulang kebutuhan publik dan policy Storage.

## 4. Periksa Auth

1. Buka `Authentication > Providers`.
2. Aktifkan Email provider.
3. Pilih aturan konfirmasi email sesuai kebutuhan pengujian.
4. Untuk pengujian lokal, gunakan email yang dapat menerima pesan jika confirmation aktif.

Trigger `on_signup` membuat baris `profiles` setelah user baru dibuat.

## 5. Periksa Row Level Security

RLS harus aktif pada seluruh tabel aplikasi. Periksa melalui `Authentication > Policies` atau SQL Editor.

Policy minimum yang berasal dari schema:

- Pembacaan publik untuk data yang memang ditampilkan publik.
- Insert campaign hanya jika `owner_id = auth.uid()`.
- Insert allocation hanya untuk pemilik campaign.
- Insert proof hanya untuk pemilik campaign yang sudah berakhir.
- Insert post hanya jika `user_id = auth.uid()`.
- Pembacaan top up hanya untuk pemiliknya.

Agent wajib menguji akses menggunakan dua akun berbeda. Jangan menganggap policy benar hanya karena query berhasil dari dashboard.

## 6. Ambil konfigurasi API

Buka:

```text
Project Settings > API
```

Ambil:

- `Project URL`
- `Publishable key`

Gunakan publishable key pada aplikasi Flutter. Jangan gunakan `service_role` key.

## 7. Jalankan aplikasi

Windows CMD:

```bat
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

PowerShell:

```powershell
flutter pub get
flutter run `
  --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

## 8. Build APK

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Jangan menulis key asli ke `README.md`, commit, issue, log, atau screenshot.

## 9. Smoke test Supabase

### Auth

1. Daftarkan akun baru.
2. Periksa user pada `Authentication > Users`.
3. Periksa profile pada `Table Editor > profiles`.
4. Masuk.
5. Keluar.

### Campaign

1. Masuk sebagai penggalang dana.
2. Buat campaign.
3. Isi target positif.
4. Isi alokasi dengan total sama dengan target.
5. Pastikan campaign dan allocation tersimpan.
6. Uji total alokasi tidak sama dengan target.

### Donasi

1. Siapkan dua akun.
2. Pastikan akun donatur memiliki saldo.
3. Donasikan nominal positif.
4. Pastikan saldo donatur berkurang.
5. Pastikan `collected` bertambah.
6. Pastikan row `donations` dibuat.
7. Uji nominal melebihi saldo.
8. Pastikan transaksi ditolak secara atomik.

### Bukti

1. Pemilik mengakhiri campaign.
2. Uji upload sebelum campaign berakhir dan pastikan ditolak.
3. Uji kamera dan lokasi.
4. Periksa file pada bucket `proofs`.
5. Periksa metadata pada tabel `proofs`.
6. Uji mock GPS.
7. Pastikan lokasi mock ditolak.

## 10. Perbaikan wajib sebelum produksi

### RPC donate

Schema saat ini melakukan update saldo dengan kondisi campaign, tetapi belum memvalidasi saldo cukup secara eksplisit. Agent wajib memperbaiki fungsi `donate` dengan aturan berikut:

- Tolak nominal kurang dari atau sama dengan nol.
- Kunci baris profile dan campaign selama transaksi.
- Tolak saldo kurang dari nominal.
- Tolak campaign tidak aktif.
- Update saldo dan collected dalam satu transaksi.
- Insert donation hanya jika seluruh validasi berhasil.

### Top up

`topup` saat ini adalah demo. Jangan gunakan untuk uang nyata. Ganti dengan payment gateway dan webhook server-side sebelum produksi.

### Storage

Review apakah bucket `proofs` boleh publik. Jika tidak, gunakan bucket privat dan signed URL.

### Data pribadi

Review akses publik terhadap `profiles`, `donations`, dan koordinat GPS. Terapkan prinsip akses minimum.

## 11. Troubleshooting

### Aplikasi menampilkan konfigurasi kosong

Jalankan ulang dengan dua `--dart-define` yang benar. Nilai tersebut bersifat case-sensitive.

### Auth berhasil tetapi profile tidak ada

Periksa trigger `on_signup`, fungsi `handle_new_user`, dan log PostgreSQL.

### Query ditolak RLS

Periksa session user, `auth.uid()`, policy tabel, dan jenis operasi query.

### Upload foto ditolak

Periksa permission kamera, permission lokasi, bucket `proofs`, dan policy `storage.objects`.

### APK build gagal karena cache

```bash
flutter clean
flutter pub get
flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
```

## Checklist serah terima

- [ ] Project Supabase aktif.
- [ ] Schema berhasil dijalankan.
- [ ] Tabel tersedia.
- [ ] Function tersedia.
- [ ] Trigger signup aktif.
- [ ] Storage bucket tersedia.
- [ ] Auth Email aktif.
- [ ] RLS aktif dan diuji dengan dua akun.
- [ ] URL dan publishable key sudah diuji.
- [ ] Service role tidak masuk repository.
- [ ] Auth smoke test lulus.
- [ ] Campaign smoke test lulus.
- [ ] Donasi smoke test lulus.
- [ ] Bukti GPS smoke test lulus.
- [ ] APK release berhasil dibangun.
