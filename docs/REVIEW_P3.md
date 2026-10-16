# Review P3 — AI Scaffold, Runnable App, dan Pemahaman Kode

Dokumen ini menjelaskan kesesuaian Decentradonate terhadap ketentuan P3: menggunakan Gemini/AI untuk membantu menghasilkan kode berdasarkan spesifikasi, mempelajari struktur proyek terlebih dahulu, menjalankan aplikasi sampai UI muncul, memperbaiki masalah jika belum berjalan, dan memastikan mahasiswa dapat menjelaskan komponen serta alur data.

## 1. Penggunaan Gemini/AI

Gemini digunakan sebagai alat bantu untuk membuat draft awal beberapa bagian kode dan rancangan UI. Bagian yang dibantu AI meliputi:

- draft `AsyncNotifier` untuk daftar campaign,
- draft validasi form donasi,
- draft widget test untuk loading, loaded, empty, error, validasi, dan submit loading,
- draft konsep visual "Riak" yang kemudian diterjemahkan ke Flutter.

Catatan prompt dan bagian yang diperiksa manual ada di `docs/tugas-statemgmt/PROMPT_LOG.md`.

## 2. Struktur Proyek yang Dipelajari

Sebelum perubahan dilakukan, struktur project dipelajari berdasarkan folder utama berikut:

```text
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── providers/
│   ├── router/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── auth/
│   ├── campaign/
│   ├── donation/
│   ├── explorer/
│   ├── proof_of_impact/
│   ├── profile/
│   └── wallet/
└── services/
```

Project memakai pendekatan feature-first dan Clean Architecture. UI ada di `presentation`, logic state ada di provider/notifier, kontrak ada di `domain`, dan implementasi data ada di `data/repositories` atau `services`.

## 3. Komponen Utama dan Alur Data

### Campaign List dan Detail

- UI: `lib/features/campaign/presentation/screens/home_screen.dart`
- Card UI: `lib/features/campaign/presentation/widgets/campaign_card.dart`
- Provider: `lib/features/campaign/presentation/providers/campaign_list_provider.dart`
- Repository: `lib/features/campaign/data/repositories/campaign_repository_impl.dart`
- Entity: `lib/features/campaign/domain/entities/campaign.dart`

Alur data: Home membaca `campaignListProvider`, provider memanggil repository, repository mengembalikan daftar campaign atau error, lalu UI menampilkan loading, data, empty, atau error dengan retry.

### Donasi

- UI form: `lib/features/donation/presentation/widgets/donate_bottom_sheet.dart`
- Provider: `lib/features/donation/presentation/providers/donation_providers.dart`
- Repository: `lib/features/donation/data/repositories/donation_repository_impl.dart`

Alur data: user memasukkan nominal, form memvalidasi input, provider mengubah state menjadi loading, repository memproses transaksi, lalu UI menampilkan sukses atau error. Guard `state.isLoading` mencegah double submit.

### Auth, Profile, dan Organizer

- Auth screens: `lib/features/auth/presentation/screens/auth_screens.dart`
- Auth repository: `lib/features/auth/data/repositories/auth_repository_impl.dart`
- Profile screen: `lib/features/profile/presentation/screens/profile_screens.dart`
- Supabase config: `lib/core/constants/supabase_config.dart`

Alur data: signup/login memakai Supabase Auth. Setelah user dibuat, tabel `profiles` menyimpan username, email, nomor HP, avatar URL, dan role. Role `organizer` mengaktifkan akses fitur campaign organizer dan proof-of-impact.

### Proof-of-Impact

- UI: `lib/features/proof_of_impact/presentation/screens/upload_proof_screen.dart`
- Provider: `lib/features/proof_of_impact/presentation/providers/proof_of_impact_provider.dart`
- Repository: `lib/features/proof_of_impact/data/repositories/proof_of_impact_repository_impl.dart`

Alur data: hanya organizer yang melihat tab Proof. Kamera baru aktif setelah tombol ditekan. Setelah foto diambil, foto tampil di UI. Saat submit, foto diunggah ke IPFS dan Supabase Storage, metadata disimpan ke tabel `proof_of_impact`.

### Wallet dan History

- Wallet: `lib/features/wallet/presentation/screens/wallet_screen.dart`
- History: `lib/features/explorer/presentation/screens/explorer_screen.dart`

Wallet berisi pembuatan/import wallet, alamat, saldo, dan backup. History hanya menampilkan riwayat transaksi donasi campaign.

## 4. Perbaikan Saat Aplikasi Belum Berjalan

Beberapa masalah yang ditemukan dan diperbaiki selama pengujian:

- Supabase belum terkonfigurasi saat APK dibuild tanpa `--dart-define`.
- Email verification sempat mengarah ke `localhost`, lalu diperbaiki memakai deep link Android.
- Profile menampilkan `Sesi belum tersedia`, lalu ditambahkan fallback tombol login/signup dan handling session.
- Tab Proof awalnya terlihat untuk semua user, lalu dibatasi hanya untuk organizer.
- Kamera Proof awalnya langsung aktif, lalu diubah menjadi aktif setelah tombol aksi.
- Detail campaign awalnya tidak menampilkan foto campaign yang sama dengan Home, lalu diperbaiki memakai `campaign.imageUrl`.
- Hardhat di HP sempat gagal karena `127.0.0.1` mengarah ke HP, lalu digunakan `adb reverse tcp:8545 tcp:8545` untuk uji perangkat fisik.

## 5. Bukti Runnable dan Pengujian

Pengujian otomatis terakhir:

```text
flutter test
20 tests passed
```

Test mencakup:

- validator nominal donasi,
- initial loading,
- loaded state,
- empty state,
- error state dengan retry,
- validasi form,
- submit loading anti double tap,
- sukses donasi,
- error donasi.

Aplikasi juga sudah beberapa kali dibuild dan dipasang ke perangkat Android fisik memakai:

```powershell
flutter build apk --debug --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
adb install -r -d build\app\outputs\flutter-apk\app-debug.apk
```

Untuk menjalankan langsung:

```powershell
flutter run -d 7edf40f --dart-define=SUPABASE_URL=https://zazwivipzlfnghfjpwun.supabase.co --dart-define=SUPABASE_ANON_KEY=public-key
```

## 6. Status Review

Status aplikasi saat ini:

- UI berhasil muncul.
- Aplikasi runnable di Android fisik dan web Chrome.
- State management memakai Riverpod.
- Form dan validasi berjalan.
- Supabase Auth/Profile tersedia.
- Wallet dan transaksi blockchain tersedia untuk alur web3.
- Proof-of-Impact tersedia untuk organizer.
- Test otomatis lulus: 20 test.
- Local Data & Persistence untuk kontak wallet tersedia dengan CRUD dan backend SQLite/localStorage sesuai platform.

Dengan demikian, syarat P3 terpenuhi. Catatan utama untuk demo adalah memastikan Supabase sudah memiliki tabel `profiles`, trigger `handle_new_user`, bucket `proofs`, tabel `proof_of_impact`, serta menjalankan aplikasi dengan `--dart-define` Supabase yang benar.
