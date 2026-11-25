# Menjalankan Decentradonate

## Fresh clone

Prasyarat Flutter stable 3.50.1, Node/npm, Git, Docker Desktop atau runtime yang didukung Supabase, dan browser. Untuk Android, siapkan Android SDK dan emulator.

~~~powershell
git clone <URL_REPO_KELAS> decentradonate
Set-Location decentradonate/TransparanBerbagi
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub
~~~

Untuk fresh clone lokal dari workspace pengembangan, ganti URL repo dengan path repo lokal. Folder aplikasi di repo adalah `TransparanBerbagi`.

## Backend lokal

~~~powershell
npx.cmd --yes supabase@3.2.0 start -x studio,edge-runtime,postgres-meta,imgproxy,logflare,vector,supavisor
npx.cmd --yes supabase@3.2.0 migration list
Get-Content -Raw supabase/tests/rls.sql | docker exec -i supabase_db_TransparanBerbagi psql -X -v ON_ERROR_STOP=1 -U postgres -d postgres
~~~

Startup pertama mengunduh image Docker serta menerapkan migrasi dan seed. Perintah berikut membuat konfigurasi yang diabaikan Git. Jika sudah punya konfigurasi lokal sendiri, pakai nama file baru agar konfigurasi lama tetap tersedia.

~~~powershell
$local = (npx.cmd --yes supabase@3.2.0 status -o json) | ConvertFrom-Json
@{
  APP_ENV = 'dev'
  SUPABASE_URL = $local.API_URL
  SUPABASE_PUBLISHABLE_KEY = $local.PUBLISHABLE_KEY
} | ConvertTo-Json | Set-Content config/web.local.json
~~~

## Jalankan dan build

~~~powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 --dart-define-from-file=config/web.local.json
~~~

Buka http://127.0.0.1:8080. Cari **Buku untuk taman baca** di katalog. Untuk OTP, kirim kode ke alamat email uji dan buka Mailpit di http://127.0.0.1:54324. Masukkan kode terbaru, cek akses donatur, lalu keluar. Untuk Android, salin konfigurasi lokal dan ganti host menjadi `10.0.2.2` jika memakai emulator Android Studio.

~~~powershell
flutter build web --no-pub --no-web-resources-cdn --base-href=/decentradonate/ --dart-define-from-file=config/web.local.json
~~~

Artefak ada di `build/web`. Build JavaScript digunakan karena adapter penyimpanan aman berbasis web masih memiliki impor JS lama.

## Deployment VPS atau perangkat arm64

Aktifkan endpoint Supabase yang bisa dijangkau browser reviewer melalui HTTPS. Siapkan instance itu dengan migrasi proyek dan akun demo khusus. Konfigurasi lokal hanya cocok untuk browser di mesin pengembangan. Untuk build deployment, isi konfigurasi staging dengan URL API HTTPS dan publishable key staging. Gunakan `--base-href=/decentradonate/` dan salin isi `build/web` ke direktori `decentradonate` di root situs HTTPS. Konfigurasikan TLS yang dipercaya browser pada server publik. Contoh lokasi Nginx pada virtual host HTTPS yang sudah aktif:

~~~nginx
location /decentradonate/ {
    try_files $uri $uri/ /decentradonate/index.html;
}
location = /decentradonate/flutter_bootstrap.js {
    add_header Cache-Control "no-cache";
}
~~~

Jangan ekspos port PostgreSQL atau Mailpit ke internet. Cek URL reviewer, baca kampanye publik, jalankan OTP dengan akun demo, periksa keamanan, lalu catat hanya masalah yang direproduksi pada GitHub Issues. Deployment VPS dan RPi/Orange Pi memerlukan target serta akses.

Lihat [arsitektur](docs/arsitektur.md), [checklist MVP](checklist_mvp.md), dan [catatan keamanan](docs/pengujian-keamanan.md).
