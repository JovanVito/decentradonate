# Checklist MVP Decentradonate

MVP kelas menampilkan katalog kampanye dan laporan dana publik, serta login OTP dan pemeriksaan akses penyelenggara.

| ID | User story | Acceptance criteria | Verifikasi |
|---|---|---|---|
| US-01 | Sebagai donatur, saya ingin masuk menggunakan OTP | Email salah ditolak. Kode harus enam digit. Kode valid membuka akun donor. Keluar menghapus sesi lokal. | Unit **PASSED**. OTP Mailpit, pemulihan sesi, dan logout melalui UI **PASSED**. |
| US-02 | Sebagai pengurus, saya ingin area penyelenggara dilindungi | Akun donor tidak dapat membuka area penyelenggara. Status persetujuan dibaca dari database. | Widget, guard URL di browser, dan RLS **PASSED**. |
| US-03 | Sebagai pengunjung, saya ingin mencari kampanye yang terbuka untuk publik | Hasil dapat dicari berdasarkan judul, penyelenggara atau kategori. Pencarian yang tidak cocok menampilkan kondisi kosong. | Unit dan pencarian browser termasuk hasil kosong **PASSED**. |
| US-04 | Sebagai pengunjung, saya ingin membaca detail dan progres kampanye | Detail berisi cerita, penyelenggara, dana, target dan jumlah donatur. Progress tidak melampaui 100 persen. | Unit dan detail di browser **PASSED**. |
| US-05 | Sebagai pengunjung, saya ingin mengetahui penggunaan dana | Ringkasan menunjukkan terkumpul, teralokasi dan sisa. Linimasa hanya memuat alokasi published dan menampilkan kondisi kosong jika belum ada. | Unit saldo dan alokasi serta ringkasan browser **PASSED**. RLS memverifikasi visibilitas alokasi terbit. |

## Unit test

- `test/email_otp_test.dart` — validasi email dan kode.
- `test/campaign_search_test.dart` — pencarian tanpa membedakan kapitalisasi.
- `test/campaign_progress_test.dart` — progres normal, lebih target, dan target nol.
- `test/campaign_balance_test.dart` — saldo dalam Rupiah integer.
- `test/published_allocation_test.dart` — koreksi negatif dan waktu publikasi.
- `test/widget_test.dart` — empat tes tambahan untuk akses dan konfigurasi.

Git mencatat OTP dan pembatasan peran pada `3bba38f`, kode produksi pada `b5cb07d`, dan unit test pada `2b047e0`.

## Pengumpulan eksternal

- [ ] Bukti generasi Gemini dan review mahasiswa.
- [x] [Pull request #1](https://github.com/JovanVito/decentradonate/pull/1) digabung ke main.
- [x] Backend Supabase staging di HTTPS. RLS dan katalog terverifikasi.
- [ ] Terbitkan Firebase Hosting dan verifikasi dari jaringan reviewer.
- [ ] Triase temuan pascadeploy. Buat issue dengan langkah reproduksi, perbaiki, dan verifikasi sebelum ditutup.

Repo tujuan adalah JovanVito/decentradonate. [Issue #2](https://github.com/JovanVito/decentradonate/issues/2) mencatat prasyarat OTP yang ditemukan pada staging. Penghitungan 10 bug pascadeploy menunggu pengujian aplikasi setelah URL publik tersedia.

## Bukti lokal

- Fresh clone pada commit kode dan tes `2b047e0` berhasil memasang dependensi dari cache, menjalankan analisis, meluluskan 11 tes, dan membangun Flutter Web untuk subpath `/decentradonate/`.
- Supabase lokal sehat. Skrip RLS selesai sampai `ROLLBACK`.
- Browser Edge menjalankan build fresh clone dengan Supabase lokal. Demo mencakup pencarian hasil kosong dan hasil cocok, progres, transparansi, OTP Mailpit, penolakan area organizer, pemulihan sesi dan logout.
- [Video demo](demo.mp4) dan [screenshot detail kampanye](docs/screenshot-mvp.png).