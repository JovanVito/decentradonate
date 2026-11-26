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
            └── Storage bucket proofs
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

- `profiles`: profil dan saldo pengguna.
- `campaigns`: campaign penggalangan dana.
- `allocations`: rencana penggunaan dana.
- `donations`: transaksi donasi.
- `topups`: riwayat top up.
- `proofs`: foto, keterangan, dan koordinat bukti penyaluran.
- `posts`: posting komunitas.

Database memakai trigger pembuatan profile, RPC untuk transaksi, Row Level Security, dan Storage bucket `proofs`.

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

1. Buat project di dashboard Supabase.
2. Buka `SQL Editor`.
3. Jalankan seluruh isi `supabase_schema.sql` sekali.
4. Buka `Project Settings > API`.
5. Salin `Project URL` dan `Publishable key`.
6. Jalankan aplikasi dengan konfigurasi berikut:

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Untuk build APK:

```bash
flutter build apk --release --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Jangan masukkan `service_role` key ke aplikasi Flutter. Gunakan hanya publishable key.

## Android

Manifest menyediakan permission internet, kamera, fine location, dan coarse location. Saat fitur bukti digunakan, izinkan kamera dan lokasi pada device.

## Testing dan Build

```bash
dart analyze
flutter test
flutter build apk --debug
```

APK release berada di:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Catatan: `topup` masih demo. Produksi wajib memakai payment gateway dan webhook server-side. RLS, akses Storage, dan kebijakan privasi juga perlu diaudit sebelum deployment.
