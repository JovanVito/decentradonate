# Donasi Transparan (Flutter + Supabase)

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

## Fitur

- Auth email
- Campaign dan alokasi dana
- Donasi
- Dompet dan riwayat transaksi
- Komunitas
- Bukti penyaluran dengan kamera dan GPS
- Catatan lokal dengan persistence browser/device

## Android

Manifest sudah berisi permission internet, kamera, dan lokasi. Saat fitur bukti digunakan, izinkan kamera dan lokasi pada device.

Catatan: `topup` masih demo. Produksi wajib memakai payment gateway dan webhook server-side.
