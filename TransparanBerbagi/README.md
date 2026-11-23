# TransparanBerbagi

Aplikasi Flutter untuk donasi dengan bukti penggunaan dana. Lihat [arsitektur, ERD, alur, dan design system](docs/phase-00.md).

## Menjalankan fondasi

Gunakan Flutter stable 3.50.1 atau lebih baru pada seri yang kompatibel dengan Dart 3.14. Persiapkan Android SDK untuk emulator/perangkat atau Xcode di macOS untuk iOS.

~~~sh
flutter pub get
flutter analyze
flutter test
flutter run
~~~

Tanpa konfigurasi, aplikasi berjalan sebagai pratinjau Fase 1. Dua pintu masuk tersedia untuk memeriksa navigasi. OTP, kampanye, pembayaran, transparansi, dan kemampuan penyelenggara belum aktif.

Salin salah satu contoh di folder config menjadi file dengan akhiran .local.json. Isi URL proyek dan publishable key yang sesuai. Jalankan, misalnya:

~~~sh
flutter run --dart-define-from-file=config/dev.local.json
~~~

APP_ENV menerima dev, staging, atau prod. Gunakan proyek Supabase terpisah untuk masing-masing lingkungan. Ini konfigurasi Dart. Paket native memakai satu ID instalasi per platform pada fase ini. AppConfig.name mengatur nama di layar. Label peluncur mengikuti AndroidManifest.xml dan Runner/Info.plist. Ikon dan layar pembuka masih menggunakan aset template Flutter.

## Build dan signing

Untuk menguji rilis Android, buat upload keystore, salin android/key.properties.example menjadi android/key.properties, dan isi path keystore relatif terhadap folder android atau dengan path absolut beserta kredensialnya. Simpan file signing di luar Git.

~~~sh
flutter build appbundle --release --dart-define-from-file=config/prod.local.json
~~~

Untuk iOS, buka ios/Runner.xcworkspace di macOS, atur bundle ID dan Team signing, lalu jalankan:

~~~sh
flutter build ipa --release --dart-define-from-file=config/prod.local.json
~~~

Build rilis tetap memerlukan penyelesaian alur dan QA pada fase berikutnya.

## Yang perlu saya siapkan

- Supabase CLI dan Docker untuk migrasi dan tes lokal.
- Proyek Supabase dev, staging, dan prod beserta URL dan publishable key.
- SMTP produksi, akun Midtrans sandbox, dan server key gateway di Supabase Secrets ketika integrasi pembayaran siap.
- Keystore Android, akun distribusi, dan perangkat pengujian Android/iOS untuk QA rilis.

## Ringkasan Fase 1

Fondasi mencakup scaffold Android/iOS, navigasi akses terpisah, konfigurasi lingkungan, bootstrap Supabase opsional, Material 3 light/dark, ARB Indonesia, dan tes konfigurasi serta navigasi. Versi paket dikunci ke kombinasi yang tersedia lokal untuk verifikasi Flutter 3.50.1. Validasi versi terbaru seluruh paket fitur dilakukan saat integrasi masing-masing paket.
