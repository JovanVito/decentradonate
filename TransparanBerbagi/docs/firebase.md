# Firebase untuk review Decentradonate

Firebase App Distribution mengirim APK ke penguji Android. Firebase Hosting menyajikan build web melalui URL HTTPS untuk reviewer. Keduanya menggunakan backend Supabase staging agar aplikasi dapat membaca data dari jaringan reviewer.

## Status staging

Supabase staging Decentradonate sudah aktif di wilayah Singapura. Migrasi, seed, akses katalog HTTPS, dan RLS terverifikasi. Firebase Hosting Emulator berhasil menjalankan Flutter Web dengan data dari backend tersebut. Supabase staging memiliki [endpoint HTTPS](https://vvmbjtbvbxauuvgxffyo.supabase.co).

Fitur OTP cloud memerlukan SMTP kustom dan template enam digit. Supabase membatasi SMTP bawaan pada anggota organisasi, dan proyek Free baru membutuhkan SMTP kustom untuk mengedit template. Masalah ini dilacak pada [issue #2](https://github.com/JovanVito/decentradonate/issues/2). Setelah pengirim terverifikasi tersedia, masukkan konfigurasi SMTP pada dashboard Supabase lalu gunakan template pada `supabase/templates/email-otp.html` untuk Confirm signup dan Magic Link. [Dokumentasi SMTP](https://supabase.com/docs/guides/auth/auth-smtp) · [Kebijakan template email](https://supabase.com/changelog/46599-changes-to-email-template-customisation-on-free-tier)

## Prasyarat

- Project Firebase tujuan dan akun yang memiliki akses ke App Distribution serta Hosting.
- Android SDK untuk build APK. Android app di Firebase harus memakai package ID yang tertera pada `android/app/build.gradle.kts`, yaitu `id.transparanberbagi.transparan_berbagi`.
- Supabase staging melalui HTTPS, dua migrasi proyek, data demo, dan konfigurasi email OTP yang bisa diakses penguji. Isi `config/staging.local.json` dari contoh staging dengan URL dan publishable key.

~~~powershell
npx.cmd --yes firebase-tools login
npx.cmd --yes firebase-tools projects:list
~~~

Daftarkan Android app lewat **Project settings → Your apps** pada project yang dipilih. Ambil Firebase App ID Android dengan format `1:...:android:...`. Selama Firebase hanya dipakai untuk mendistribusikan APK, integrasi SDK Firebase di aplikasi tidak diperlukan.

## APK untuk penguji

~~~powershell
flutter build apk --debug --dart-define-from-file=config/staging.local.json
npx.cmd --yes firebase-tools appdistribution:distribute build/app/outputs/flutter-apk/app-debug.apk --app <ANDROID_APP_ID> --release-notes "Decentradonate MVP kelas"
~~~

Gunakan grup penguji atau tester yang sudah disetujui. Tautan distribusi dan status undangan muncul setelah build diunggah. Untuk release, gunakan keystore yang sesuai. [Panduan App Distribution Android](https://firebase.google.com/docs/app-distribution/android/distribute-cli?apptype=apk)

## URL demo web

`firebase.json` sudah mengarah ke build Flutter Web dan memiliki fallback ke halaman utama. Pilih project secara eksplisit pada setiap deploy. Buat preview channel untuk uji sebelum promosi ke live.

~~~powershell
flutter build web --no-pub --no-web-resources-cdn --dart-define-from-file=config/staging.local.json
npx.cmd --yes firebase-tools hosting:channel:deploy reviewer --project <FIREBASE_PROJECT_ID>
~~~

Setelah alur utama diuji dari browser reviewer, deploy ke channel live bila diperlukan.

~~~powershell
npx.cmd --yes firebase-tools deploy --only hosting --project <FIREBASE_PROJECT_ID>
~~~

Jangan publikasikan build yang mengarah ke API localhost. Firebase Hosting memberi URL HTTPS pada domain proyek, yang dapat digunakan sebagai tautan percobaan jika disetujui reviewer. Jika penilaian tetap mewajibkan VPS, RPi, atau Orange Pi, ikuti prosedur di HowToRun.md. [Referensi Firebase CLI](https://firebase.google.com/docs/cli/)
