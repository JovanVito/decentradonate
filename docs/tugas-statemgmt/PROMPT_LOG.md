# Catatan Bantuan AI dan Pemeriksaan Manual

Sesuai ketentuan tugas, bagian ini mencatat prompt AI yang dipakai serta
bagian yang diperiksa atau diperbaiki sendiri. Prinsipnya: AI dipakai
untuk boilerplate dan draf test, keputusan akhir tetap di tangan penulis.

## Prompt yang Dipakai

1. Prompt: "Buatkan draf AsyncNotifier untuk daftar campaign dengan
   repository yang bisa diset gagal dan kosong untuk keperluan demo."
   Hasil: dipakai sebagai dasar `campaign_list_provider.dart` dan
   `campaign_repository_impl.dart`. Yang diperbaiki sendiri: retry memakai
   `ref.invalidateSelf` supaya hitung ulang dari repository, pesan error
   dibersihkan dari awalan "Exception: " sebelum tampil ke pengguna.

2. Prompt: "Buatkan draf validator nominal donasi dan widget test untuk
   loading, empty, error, validasi, dan double tap."
   Hasil: dipakai sebagai kerangka `validateDonationAmount` dan
   `campaign_donation_test.dart`. Yang diperbaiki sendiri: pesan validasi
   ditulis Bahasa Indonesia dan disesuaikan dengan minimal donasi 0,001,
   suffix diubah dari ETH menjadi MATIC, test dibungkus Scaffold supaya
   tidak error "No Material widget", dan test loading diakhiri dengan
   `pumpAndSettle` supaya tidak ada timer menggantung.

3. Prompt: "Review guard double submit untuk AsyncNotifier donasi."
   Hasil: saran guard `if (state.isLoading) return`. Diterima dan
   dipasang di `donation_providers.dart`, lalu dibuktikan lewat test
   yang menekan tombol dua kali cepat dan memastikan repository hanya
   dipanggil sekali.

## Yang Ditulis Sepenuhnya Tanpa AI

Struktur `Form` dengan `GlobalKey` dan `AutovalidateMode.onUserInteraction`
di `donate_bottom_sheet.dart`, pemisahan `wrapSheet` di test supaya
bottom sheet punya ancestor Material, dan dokumen di folder ini.

## Tanggung Jawab

Seluruh kode di atas sudah dibaca ulang, dijalankan lewat `flutter test`,
dan diperiksa lewat `flutter analyze`. Kalau ada bug saat demo, itu
tanggung jawab penulis, bukan AI.
