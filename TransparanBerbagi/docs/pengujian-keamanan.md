# Pengujian keamanan dan catatan perbaikan

| Pemeriksaan | Metode | Hasil |
|---|---|---|
| Akses baris privat | Skrip RLS menjalankan kueri sebagai beberapa role dan identitas | Tes menolak akses lintas akun, perubahan role, perubahan status pembayaran, dan alokasi tanpa hak |
| Pencabutan hak organizer | Ubah status dalam transaksi uji dan periksa akses draf | Akun yang haknya dicabut kehilangan akses draf |
| Keutuhan dana | Publikasikan pengeluaran di atas saldo, lalu publikasi nominal sah | Pengeluaran berlebih ditolak. Publikasi sah mengurangi saldo. Transaksi tes diakhiri rollback |
| Akses publik | REST memakai publishable key | Kampanye published dapat dibaca tanpa sesi |
| Akses UI | Uji kode OTP donor melalui pintu masuk organizer | Akses ditolak dan sesi uji diakhiri |
| Rahasia klien | Tinjau konfigurasi yang dikomit dan konfigurasi lokal | Prod/staging hanya memasukkan publishable key pada Flutter. File lokal diabaikan Git |

## Contoh log aman

Berikut cuplikan hasil uji tanpa token, OTP, email pengguna atau isi dokumen.

~~~text
Target: local stack (127.0.0.1:54322)
BEGIN
DO
ROLLBACK
No issues found!
All tests passed!
~~~

| Masalah yang direproduksi | Penyebab | Tindakan |
|---|---|---|
| Supabase CLI menolak file SQL RLS dengan pesan `cannot insert multiple commands into a prepared statement` | Skrip uji sengaja memakai transaksi dan beberapa statement | Jalankan melalui `psql` dalam kontainer; verifikasi `ROLLBACK` |
| Docker sebelumnya gagal menyiapkan stack | DNS registry dan koneksi unduhan image terputus | Lanjutkan dari cache dan mulai hanya layanan inti. Cek kontainer sehat dan jalankan pengujian REST |
| Dry run Wasm melaporkan impor `dart:html` pada secure storage | Adapter web saat ini masih memakai interop JS lama | Gunakan build JavaScript. Upgrade adapter sebelum mendukung Wasm |

Skrip RLS juga lulus di Supabase staging. Firebase Hosting Emulator memuat katalog dan saldo dari REST API staging melalui HTTPS. Supabase Security Advisor menampilkan satu peringatan konfigurasi tentang perlindungan kata sandi bocor. Alur UI versi ini memakai OTP. Pengiriman OTP staging ke reviewer eksternal masih membutuhkan SMTP kustom dan template enam digit.

Verifikasi UI pada Firebase Hosting publik dan APK App Distribution masih menunggu akses deployment.
