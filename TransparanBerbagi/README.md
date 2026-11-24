# Decentradonate

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

## Supabase lokal

Jalankan dari folder proyek dengan Docker Desktop aktif. Versi CLI yang dipakai adalah 3.2.0. CLI menerapkan migrasi dan seed saat menyiapkan database lokal baru.

~~~powershell
npx.cmd --yes supabase@3.2.0 start
npx.cmd --yes supabase@3.2.0 status
npx.cmd --yes supabase@3.2.0 migration list
npx.cmd --yes supabase@3.2.0 db query --file supabase/tests/rls.sql
~~~

Salin URL API serta publishable key lokal dari status yang ditampilkan di terminal ke config/dev.local.json. Gunakan http://10.0.2.2:54321 untuk emulator Android. Simulator iOS dapat memakai http://127.0.0.1:54321. Jaga secret key hanya di backend. Buka Studio dan kotak masuk lokal dari alamat yang dicetak CLI.

Template OTP di supabase/templates/email-otp.html digunakan untuk konfirmasi dan masuk. Untuk lingkungan hosted, pasang template dengan variabel Token pada Authentication → Email Templates. Aktifkan custom SMTP dan masukkan kredensial provider melalui pengaturan Auth. Samakan masa berlaku dengan konfigurasi lokal (600 detik), interval kirim (60 detik), dan uji pengiriman serta verifikasi memakai email yang Anda kontrol. [Panduan custom SMTP](https://supabase.com/docs/guides/auth/auth-smtp)

### Moderasi dan publikasi

Operator Studio dapat memanggil private.review_organizer atau private.review_campaign lewat SQL Editor menggunakan UUID dan keputusan yang sesuai. Operasi dicatat pada audit_logs. Jika dijalankan tanpa JWT pengguna aplikasi, actor_id kosong dan pelacakan operator perlu memakai log akses Studio.

Kampanye demo dan satu donasi berbayar siap untuk latihan kueri. Alokasi demo tetap berupa draf. Tes SQL memakai metadata objek sementara dan melakukan rollback. Unggahan foto serta invoice sungguhan memerlukan Storage aktif. Client dapat membuat draf dan mengunggah berkas. Pembuatan metadata bukti dan publikasi dikerjakan oleh backend tepercaya setelah memeriksa sesi, kepemilikan, persetujuan penyelenggara, dan hash isi file. Endpoint untuk alur tersebut berada di fase fitur penyelenggara.

### Ringkasan Fase 2

Dua migrasi mendefinisikan delapan tabel ber-RLS, akses berbasis peran dan kepemilikan, empat bucket privat, sinkronisasi role, audit, dan agregat dana. Tes SQL mencakup akses lintas akun, pencabutan akses organizer, penolakan pengeluaran di atas saldo, dan publikasi bukti. Migrasi, seed dan tes dijalankan di PostgreSQL WASM dengan fixture Auth dan Storage. Verifikasi melalui kontainer Supabase penuh tetap diperlukan untuk Auth, upload, URL bertanda tangan, dan Realtime.

## Foto layar masuk

Foto ilustrasi kegiatan donasi oleh [Gustavo Fring di Pexels](https://www.pexels.com/photo/people-packing-donations-7156163/).
