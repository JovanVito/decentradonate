# Donasi Transparan

Donasi Transparan adalah aplikasi Flutter untuk menghubungkan penggalang dana dan donatur melalui campaign yang transparan. Penggalang dana dapat membuat campaign, menetapkan target dan alokasi dana, menerima donasi, lalu mengunggah bukti penyaluran berupa foto dan koordinat GPS. Donatur dapat melihat perkembangan campaign, alokasi dana, riwayat donasi, dan bukti penyaluran.

## Masalah yang Diselesaikan

Informasi penggalangan dana, transaksi, alokasi, dan bukti penyaluran sering tersebar. Aplikasi ini menggabungkan seluruh informasi tersebut dalam satu tempat agar donatur dapat memantau campaign dan bukti penggunaan dana.

## Target Pengguna

- Penggalang dana yang mengelola campaign sosial.
- Donatur yang ingin memantau penggunaan donasi.
- Komunitas yang berdiskusi tentang campaign sosial.

## Fitur Utama

- Registrasi dan login email.
- Membuat campaign dengan target dan rencana alokasi dana.
- Melihat daftar dan detail campaign.
- Donasi dari saldo pengguna.
- Dompet dan riwayat transaksi.
- Komunitas untuk membuat dan membaca posting.
- Mengakhiri campaign oleh pemilik.
- Upload bukti penyaluran menggunakan kamera.
- Menyimpan latitude dan longitude bukti penyaluran.
- Menolak lokasi mock GPS.
- Catatan lokal dengan Create, Read, Update, Delete.
- Persistence catatan setelah aplikasi dibuka kembali.

## Arsitektur

Project memakai Flutter sebagai client dan Supabase sebagai backend service.

```text
Flutter UI
    │
    ├── AuthPage / Home / Campaign / Wallet / Community
    │
    ├── LocalNotesController
    │       └── LocalNoteRepository
    │               └── SharedPreferences
    │
    └── Supabase Client
            ├── Supabase Auth
            ├── PostgreSQL
            ├── RPC functions
            └── Storage privat mobile-proofs
```

### Struktur Project

```text
lib/
├── main.dart                 # bootstrap Supabase, auth, dan navigasi
├── campaign.dart             # campaign, donasi, alokasi, dan bukti penyaluran
├── wallet_community.dart      # dompet dan komunitas
├── local_repository.dart     # model dan CRUD SharedPreferences
└── local_notes.dart           # controller dan UI catatan lokal
supabase_schema.sql            # tabel, trigger, RPC, RLS, dan storage policy
Architecture.md                # dokumentasi arsitektur lengkap
test/widget_test.dart          # test model catatan lokal
```

### Backend Supabase

Supabase menyimpan data berikut:

- `mobile_profiles` menyimpan nama dan saldo demo. Pengguna membaca saldo sendiri lewat RPC.
- `mobile_campaigns` dan `mobile_allocations` menyimpan campaign beserta rencana penggunaan dana.
- `mobile_donations` dan `mobile_topups` menyimpan transaksi saldo demo.
- `mobile_proofs` menyimpan rujukan foto, keterangan, dan koordinat penyaluran.
- `mobile_posts` menyimpan kiriman komunitas.

Database membuat profil saat pendaftaran. RLS membatasi akses tabel, dan aplikasi memakai URL bertanda tangan untuk membaca foto dari bucket privat `mobile-proofs`.

### State Management

Vertical slice catatan lokal memakai `ChangeNotifier` dengan pemisahan tanggung jawab:

```text
LocalNotesPage
    → LocalNotesController
        → LocalNoteRepository
            → SharedPreferences
```

State UI yang tersedia:

- Loading awal.
- Data berhasil dimuat.
- Empty state.
- Error state dengan retry.
- Validasi input.
- Loading submit untuk mencegah double tap.

### Fitur Perangkat

- Kamera mengambil foto bukti penyaluran.
- GPS mengambil lokasi saat bukti dibuat.
- Mock GPS ditolak melalui `Position.isMocked`.
- Permission kamera dan lokasi diminta saat fitur digunakan.

## Setup Supabase

Proyek `vvmbjtbvbxauuvgxffyo` sudah menerima migrasi aplikasi. Untuk menyiapkan proyek lain, jalankan `supabase_schema.sql`, `supabase_profile.sql`, lalu `supabase_campaign_catalog.sql` melalui SQL Editor.

Buat `supabase-config.json` di direktori proyek dengan `SUPABASE_URL` dan `SUPABASE_PUBLISHABLE_KEY` dari dashboard. Git mengabaikan berkas ini.

```bash
flutter pub get
flutter run --dart-define-from-file=supabase-config.json
flutter build apk --release --dart-define-from-file=supabase-config.json
```

Jangan masukkan `service_role` key ke aplikasi Flutter. Gunakan hanya publishable key.

Di Dashboard Supabase, buka **Authentication → URL Configuration** dan tambahkan
`com.donasitransparan.mobile://auth-callback` ke **Redirect URLs**. Buka tautan
konfirmasi dari email di ponsel yang dipakai untuk mendaftar agar sesi dapat
dibuat di aplikasi tersebut.

## Android

Manifest menyediakan permission internet, kamera, fine location, dan coarse location. Saat fitur bukti digunakan, izinkan kamera dan lokasi pada device.

## Testing dan Build

```bash
dart analyze
flutter test
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

APK release berada di:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Saldo aplikasi dibatasi hingga Rp1.000.000 per akun. Donasi minimum Rp5.000 dicatat di Supabase. Pembayaran dan pencairan dana berada di luar cakupan MVP.

## Katalog dan forum

Katalog campaign memakai foto ilustrasi berlisensi Pexels. Forum menggabungkan percakapan terjadwal dengan nama sintetis dan kiriman pengguna dari Supabase. Catatan awal ditambahkan sekali dan dapat diubah atau dihapus.

- [Paket sekolah](https://www.pexels.com/photo/28503361/)
- [Air bersih](https://www.pexels.com/photo/9692261/)
- [Dapur warga](https://www.pexels.com/photo/39006612/)
- [Mangrove](https://www.pexels.com/photo/35125736/)
- [Perpustakaan](https://www.pexels.com/photo/34085957/)
- [Kebun pangan](https://www.pexels.com/photo/38843811/)
- [Kursi roda](https://www.pexels.com/photo/20272758/)
- [Kelas menjahit](https://www.pexels.com/photo/18181981/)
- [Listrik surya](https://www.pexels.com/photo/7211069/)
- [Ruang kelas](https://www.pexels.com/photo/36650153/)
