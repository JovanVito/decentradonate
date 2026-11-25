# Arsitektur Decentradonate

## Tiga alternatif tema

| Tema | Masalah yang ditangani | Pengguna | Batas prototipe |
|---|---|---|---|
| Transparansi bantuan komunitas | Donatur sulit mengetahui penggunaan dana setelah uang diserahkan | Donatur komunitas, pengurus, peninjau | Katalog, status akses dan laporan alokasi |
| Pelaporan fasilitas kampus | Laporan kerusakan tersebar di beberapa kanal tanpa status baku | Mahasiswa, petugas fasilitas | Kirim laporan, triase, dan status |
| Peminjaman alat kegiatan | Benturan jadwal muncul saat ketersediaan alat dikelola di chat | Panitia UKM, pengelola inventaris | Katalog alat, reservasi, konfirmasi |

**Pilihan** — Transparansi bantuan komunitas. Proyek berangkat dari masalah koordinasi yang dapat diamati ketika informasi pengumpulan dana, penggunaan dana, dan status kampanye tersebar. Asumsi masalah ini belum divalidasi melalui wawancara. Target utama adalah donatur yang ingin memeriksa kegiatan komunitas sebelum atau sesudah memberi bantuan. Pengurus terverifikasi dan peninjau internal adalah pengguna sekunder. Aplikasi menyajikan cerita kampanye, progres, dan ringkasan penggunaan dana di tempat yang dapat diakses tanpa akun.

## Ruang lingkup 12 pertemuan

MVP kelas adalah **katalog kampanye dengan transparansi dana dan akses akun berbasis peran**. Lima user story yang mengikat cakupan tercantum pada checklist. Alur organizer dalam versi ini berhenti pada pemeriksaan akses. QRIS, pemindahan uang, formulir pengajuan dan unggah legalitas, kamera/GPS, push notification, dan panel administrasi bukan bagian dari MVP kelas. Ini adalah subset dari rancangan produk pada [rencana awal](phase-00.md). Reviewer berhasil mendemonstrasikan MVP jika dapat masuk sebagai donatur lewat OTP lokal, membuka dan mencari kampanye, melihat progres dan saldo, serta gagal memasuki akun penyelenggara dengan sesi donatur.

| Pertemuan | Sasaran |
|---|---|
| 1–2 | Bandingkan alternatif, tentukan masalah, role, dan batas proyek |
| 3–4 | Arsitektur, Supabase lokal, scaffold, dan UI awal |
| 5 | Iterasi OTP dan pembatasan akses. Verifikasi dan catat commit |
| 6–7 | Katalog, pencarian, detail dan transparansi dana |
| 8–9 | Lima unit test, regresi UI, RLS, dan build web |
| 10 | Fresh clone, petunjuk demo, dan perbaikan konfigurasi |
| 11–12 | Deploy ke target yang diberikan, rekam demo, triase dan perbaiki temuan nyata |

## Komponen dan data

~~~mermaid
flowchart LR
  D[Donatur atau pengunjung] --> UI[Flutter Material UI]
  O[Penyelenggara] --> UI
  UI --> R[Riverpod dan go_router]
  R --> A[AccessRepository]
  R --> C[CampaignRepository]
  A --> AUTH[Supabase Auth]
  AUTH --> MAIL[Mailpit lokal]
  A --> API[Supabase REST]
  C --> API
  AUTH --> PG[(PostgreSQL)]
  API --> PG
  PG --> POL[RLS dan trigger]
~~~

- Flutter menggunakan Material UI, Riverpod untuk repository dan status asinkron, serta go_router untuk URL dan pemeriksaan role. AppConfig hanya menerima publishable key di klien.
- OTP memakai Supabase Auth. Trigger membuat profil donor ketika akun Auth dibuat. Saat membuka area organizer, repository membaca role profil dan status approval. Status server memegang otoritas. Flutter menyimpan sesi dengan secure storage perangkat atau penyimpanan berbasis origin pada web. Mailpit hanya digunakan di pengembangan lokal.
- Katalog meminta kampanye publik dari REST Supabase. Detail mengambil cerita dan agregat dengan ID kampanye. Linimasa membaca alokasi published. PostgreSQL melindungi baris privat dengan RLS dan menentukan nilai saldo. Flutter menghitung selisih dari agregat yang diterima dan membatasi nilai progress bar ke rentang 0–1.
- Bucket privat dan aturan publikasi bukti ada di backend. MVP menampilkan ringkasan dan catatan alokasi, sedangkan galeri dan unggah bukti masih di luar cakupan.

~~~mermaid
sequenceDiagram
  actor U as Pengunjung
  participant F as Flutter
  participant A as Supabase Auth
  participant M as Mailpit
  participant P as REST dan PostgreSQL
  U->>F: Masukkan email
  F->>A: Minta OTP
  A->>M: Kirim kode
  U->>F: Masukkan kode
  F->>A: Verifikasi
  A-->>F: Sesi
  F->>P: Baca profil sendiri dengan token
  P-->>F: Role sesuai RLS
  U->>F: Buka detail kampanye
  F->>P: Baca kampanye dan alokasi terbit
  P-->>F: Agregat dana dan linimasa
~~~

## Peta repo

| Lokasi | Isi |
|---|---|
| `lib/core` | Konfigurasi, tema dan router |
| `lib/features/access` | Login, sesi, role dan validasi OTP |
| `lib/features/campaigns` | Model, repository, katalog dan detail |
| `supabase/migrations` | Skema, RLS, bucket, audit, dan aturan transaksi |
| `supabase/seed.sql` | Kampanye demo, donasi dan draf alokasi |
| `test` dan `supabase/tests` | Tes Dart dan pemeriksaan database |

## Proses Pertemuan 5

| Fitur | Brief | Plan | Build | Verify | Commit |
|---|---|---|---|---|---|
| Akses dengan OTP | Donatur butuh akses tanpa kata sandi | Form email dan kode, Supabase Auth, profil default | Repository Auth, validasi, penyimpanan sesi dan logout | OTP aktual di Mailpit, verifikasi profil donor dan logout | `3bba38f` |
| Katalog dan detail kampanye | Pengunjung perlu menemukan kampanye dan membaca penggunaan dana | Repository baca publik, pencarian lokal, detail dan ringkasan dari agregat | Katalog, detail, progres, status kosong dan linimasa | Unit, REST, dan build web sesuai checklist | Lihat commit `feat: add public campaign MVP and web entrypoint` |

AI Agent membantu membuat draf arsitektur, implementasi Flutter, dan tes. Kontribusi review atau perubahan mahasiswa belum dicatat. Saat presentasi, mahasiswa melengkapi catatan dengan diff yang benar-benar direview, perubahan yang dibuat sendiri, dan alasan teknisnya. Rubrik Gemini memerlukan sesi atau bukti keluaran Gemini. Pengerjaan repositori pada chat ini menggunakan Codex.
