# Catatan Bantuan AI dan Pemeriksaan Manual

Dokumen ini mencatat penggunaan AI dalam pengerjaan fitur sesuai ketentuan tugas. AI digunakan sebagai alat bantu untuk membuat draft/scaffold, bukan sebagai pengganti pemahaman kode. Seluruh kode yang masuk repo tetap diperiksa, dijalankan, dan diperbaiki secara manual sebelum dipush.

## AI yang Digunakan

AI utama yang digunakan adalah **Gemini** untuk membantu menghasilkan draft awal berdasarkan spesifikasi P3, terutama pada bagian state management, form, validasi, dan test. Selain itu, AI assistant di lingkungan coding digunakan untuk review, refactor, dan verifikasi perubahan.

## Prompt yang Dipakai

1. Prompt: "Buatkan draf AsyncNotifier untuk daftar campaign dengan repository yang bisa diset gagal dan kosong untuk keperluan demo."
   Hasil: dipakai sebagai dasar `campaign_list_provider.dart` dan `campaign_repository_impl.dart`.
   Pemeriksaan/perbaikan manual: retry dibuat memakai `ref.invalidateSelf`, pesan error dibersihkan dari awalan `Exception:`, dan alur repository dipastikan tetap mengikuti Clean Architecture.

2. Prompt: "Buatkan draf validator nominal donasi dan widget test untuk loading, empty, error, validasi, dan double tap."
   Hasil: dipakai sebagai kerangka `validateDonationAmount` dan `campaign_donation_test.dart`.
   Pemeriksaan/perbaikan manual: pesan validasi ditulis dalam Bahasa Indonesia, minimal donasi disesuaikan menjadi 0,001, suffix diubah dari ETH menjadi MATIC, test dibungkus dengan `Scaffold`, dan test loading ditutup dengan `pumpAndSettle` agar tidak ada timer menggantung.

3. Prompt: "Review guard double submit untuk AsyncNotifier donasi."
   Hasil: saran guard `if (state.isLoading) return`.
   Pemeriksaan/perbaikan manual: guard dipasang di `donation_providers.dart`, lalu dibuktikan lewat test yang menekan tombol submit dua kali dan memastikan repository hanya terpanggil sekali.

4. Prompt: "Buatkan rancangan visual aplikasi donasi blockchain dengan konsep riak air, kartu kampanye, wallet, dan proof-of-impact."
   Hasil: konsep desain disimpan sebagai `docs/Decentradonate — Konsep Desain _Riak_.html`.
   Pemeriksaan/perbaikan manual: desain tidak disalin mentah, tetapi diterjemahkan ke Flutter melalui `AppColors`, `AppTheme`, `RippleRing`, `PrimaryButton`, `CampaignCard`, dan beberapa screen utama.

## Bagian yang Diperiksa atau Diperbaiki Sendiri

- Struktur `Form` dengan `GlobalKey` dan `AutovalidateMode.onUserInteraction` pada `donate_bottom_sheet.dart`.
- Pemisahan widget, notifier/provider, repository, dan service sesuai pola project.
- Penyesuaian UI agar tetap responsive pada perangkat Android fisik.
- Konfigurasi Supabase Auth, profile, organizer role, dan proof storage.
- Deep link email verification agar tidak lagi mengarah ke localhost.
- Pembatasan fitur Proof hanya untuk penyelenggara.
- Pengujian ulang dengan `flutter test` setelah perubahan.

## Tanggung Jawab

Seluruh kode yang dikumpulkan sudah dibaca ulang, dijalankan, dan diuji. Jika ada bagian yang dibuat dari draft AI, bagian tersebut tetap dipahami dan diperbaiki sesuai kebutuhan aplikasi Decentradonate. Tanggung jawab akhir terhadap kode, alur data, dan bug tetap berada pada mahasiswa.
