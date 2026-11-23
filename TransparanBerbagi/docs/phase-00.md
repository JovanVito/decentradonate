# Fase 0 — Perencanaan TransparanBerbagi

Aplikasi baru untuk Android dan iOS. Bahasa awal Indonesia, mata uang IDR disimpan sebagai bilangan bulat tanpa pecahan. Nama tampilan Flutter berada di konfigurasi aplikasi. Nama pada peluncur OS dikelola lewat konfigurasi platform. Proyek ini berada di folder tersendiri karena brief meminta pembangunan dari nol.

## Arsitektur

Flutter stable, Dart null-safety, Riverpod untuk state dan injeksi dependensi, go_router untuk navigasi dengan guard. Presentasi memakai repository interface di domain dan implementasi Supabase di data. Struktur `lib/features/<fitur>/{data,domain,presentation}` bertambah saat fitur diimplementasikan. `lib/core` menampung konfigurasi, tema, navigasi, dan penanganan error. String UI memakai ARB Flutter. Paket kamera, GPS, formatter IDR, dan generator model ditambahkan saat fiturnya membutuhkan.

Dev, staging, dan prod memakai konfigurasi build dan proyek Supabase terpisah. Android divalidasi dulu di Windows. Build dan signing iOS memerlukan macOS/Xcode. Mode demo pengembangan memakai data fiktif dan tidak membuka sesi atau transaksi riil.

Midtrans Core API QRIS dinamis dipilih karena memiliki sandbox, endpoint status transaksi dan dokumentasi webhook. Edge Functions memakai interface PaymentProvider. Buat transaksi dengan ID order stabil, deduplikasi upaya dengan kunci idempotensi, verifikasi signature dan konfirmasi nominal, mata uang, serta status lewat endpoint status gateway. Terapkan perubahan status dan agregat dalam satu transaksi SQL. Realtime pada donasi sendiri dibantu polling saat koneksi terputus. Sebelum produksi, periksa aktivasi QRIS dan skenario bayar QR dari perangkat yang sama.

- [Flutter stable](https://docs.flutter.dev/release/release-notes)
- [Midtrans QRIS](https://docs.midtrans.com/reference/qris) dan [webhook](https://docs.midtrans.com/docs/https-notification-webhooks)
- [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security)

## Model data

~~~mermaid
erDiagram
  AUTH_USERS ||--|| PROFILES : owns
  PROFILES ||--o| ORGANIZER_PROFILES : applies
  PROFILES ||--o{ CAMPAIGNS : organizes
  CAMPAIGNS ||--o{ CAMPAIGN_UPDATES : contains
  CAMPAIGNS ||--o{ DONATIONS : receives
  PROFILES ||--o{ DONATIONS : makes
  CAMPAIGNS ||--o{ FUND_ALLOCATIONS : publishes
  PROFILES ||--o{ FUND_ALLOCATIONS : records
  FUND_ALLOCATIONS ||--o{ ALLOCATION_PROOFS : contains
  FUND_ALLOCATIONS o|--o{ FUND_ALLOCATIONS : corrects
  PROFILES o|--o{ AUDIT_LOGS : acts
~~~

- Trigger Auth membuat profil donor. Persetujuan Studio melalui operasi SQL terkontrol memperbarui status pengajuan, role profil, metadata Auth, dan audit dalam satu transaksi. RLS organizer juga memeriksa persetujuan terkini di database agar pencabutan berlaku walaupun JWT lama masih aktif. Gunakan UUID akun terverifikasi sebagai pengikat identitas.
- Terapkan RLS di semua tabel dan hak kolom/operasi minimum. Kampanye publik dapat dibaca, donasi hanya terlihat oleh pemiliknya, dan mutasi pembayaran dibatasi pada server. Uji akses lintas akun dan lintas peran menggunakan sesi berbeda.
- Pengajuan dan dokumen legalitas privat untuk pemohon dan admin. Kuasa moderasi diberikan lewat Studio kepada operator dengan akses terbatas. Catat persetujuan, publikasi, koreksi, dan perubahan pembayaran tanpa menyalin data identitas ke audit log.
- Unggah bukti ke bucket privat dengan batas MIME dan ukuran. Akses bukti publik memakai URL bertanda tangan berumur pendek sesudah pemeriksaan akses. Publikasi memverifikasi keberadaan foto dan invoice serta hash yang dihitung server. Bukti terbit bersifat immutable. Koreksi merujuk entri asal dan memengaruhi total alokasi melalui transaksi yang sama.
- Semua mutasi saldo mengunci baris kampanye yang sama. Publikasi menolak saldo negatif, mengikat bukti, mencatat audit, dan memperbarui agregat secara atomik. Refund dan rekonsiliasi yang bisa memengaruhi saldo perlu prosedur operasional sebelum go-live.
- Ambil GPS saat pemotretan. Tolak lokasi mock yang terdeteksi dan minta ulang jika akurasi di atas 50 m. Simpan waktu perangkat dan waktu server. Label pengambilan menjelaskan metode yang dilaporkan aplikasi. Perangkat yang telah dimodifikasi dapat memalsukan metadata. Minta operator memeriksa isi foto, invoice, dan lokasi publik agar data sensitif tidak terbit.

## Alur dan wireframe teks

~~~mermaid
flowchart LR
  A[Pilih akses] --> B[Email dan OTP]
  B --> C[Onboarding donor]
  C --> D[Beranda kampanye]
  D --> E[Detail, kabar, transparansi]
  E --> F[Nominal dan identitas]
  F --> G[QRIS dan status]
  C --> H[Riwayat dan bukti donasi]
  B --> I[Ajukan penyelenggara / cek status]
  I --> J[Studio: keputusan admin]
  J --> K[Masuk penyelenggara terverifikasi]
  K --> L[Dashboard dan editor kampanye]
  L --> M[Form alokasi, kamera dan GPS]
  M --> N[Invoice, pratinjau dan publikasi]
  N --> E
  L --> J
~~~

| Layar | Tata letak dan tindakan utama |
|---|---|
| Akses dan OTP | Nama aplikasi, dua pintu masuk, tautan pengajuan. OTP enam digit dengan fokus awal, paste, dan kirim ulang setelah 60 detik. |
| Onboarding dan profil | Penjelasan ringkas transparansi, tombol mulai dan keluar pada profil. |
| Beranda | Banner, pencarian, kategori, prioritas mendesak dan pilihan. Navigasi beranda, riwayat, akun. |
| Detail | Foto dan judul, penyelenggara terverifikasi, progres, donatur, hari tersisa. Tab Cerita, Kabar Terbaru, Transparansi Dana. Tombol Donasi di bawah. |
| Transparansi | Terkumpul, teralokasi, sisa. Urutan terbaru, nominal, tujuan, tanggal, foto, invoice, alamat dan tombol peta. |
| Donasi dan pembayaran | Preset, nominal khusus minimal Rp10.000, pilihan anonim, doa opsional. QR dengan waktu tersisa, simpan/bagikan dan status. |
| Riwayat | Status pembayaran, nominal, tanggal, dan layar bukti donasi. |
| Pengajuan | Identitas lembaga, dokumen, kontak, rekening, dan status pengajuan. |
| Dashboard dan editor | Status moderasi per kampanye, form pembuatan kampanye dan akses alokasi kampanye sendiri. |
| Bukti | Izin kontekstual dengan tombol pengaturan, foto kamera saja, akurasi GPS, invoice, pratinjau dan publikasi. |
| Admin | Studio untuk tinjau pengajuan, tinjau kampanye dan audit. |

## Design system

Material 3 light/dark memakai hijau kebiruan hangat dan permukaan netral. Light menggunakan primary #006B59 di atas #FFFFFF, teks #18251F, dan surface #F7FAF7. Dark menggunakan primary #7ED7BD, teks #E1EDE6, dan surface #101C17. Foreground tombol dark #00382E. Teks biasa ditargetkan minimal WCAG AA (4,5:1). Warna status selalu disertai ikon/label.

Tipografi sistem Material untuk dukungan penskalaan teks native. Ukuran heading 28, judul 20, body 16, label 14. Spacing 4, 8, 12, 16, 24, 32. Radius 12 untuk input/tombol, 16 untuk kartu, 24 untuk bottom sheet. Kartu dominan memakai garis batas, dengan elevasi ringan untuk elemen mengambang.

Tombol utama penuh pada layar sempit dengan target sentuh minimum 48 dp. Field OTP satu input berlabel agar paste dan pembaca layar berfungsi. Kartu kampanye menampilkan progres dengan label nominal. Linimasa memprioritaskan tanggal, tujuan dan nominal. Badge verifikasi punya teks. Bottom sheet mendukung tinggi dinamis dan scroll. Semua daftar memiliki skeleton, pesan kosong, gagal dengan coba lagi, dan indikator koneksi. Bukti yang belum dikirim tetap di pratinjau saat retry. Uji skala teks 200%, TalkBack dan VoiceOver pada QA.

## Ringkasan Fase 0

Rancangan menetapkan Riverpod, go_router, Supabase, Midtrans QRIS, Studio untuk moderasi, dan bukti di penyimpanan privat. Fase 1 menyiapkan proyek, konfigurasi, tema, navigasi dan tes fondasi. Integrasi layanan dilakukan setelah fondasi bisa diverifikasi.
