# Feature Donasi Campaign: State Management, Form, dan Validasi

Feature yang dikumpulkan untuk tugas ini adalah alur donasi campaign,
mulai dari daftar campaign sampai form donasi. Satu feature ini dipakai
untuk menunjukkan keenam kondisi UI yang diminta.

## Pembagian Tanggung Jawab

Widget hanya menampilkan dan meneruskan input. File-nya ada di
`lib/features/campaign/presentation/screens/home_screen.dart` untuk daftar
dan `lib/features/donation/presentation/widgets/donate_bottom_sheet.dart`
untuk form. Keduanya memakai Riverpod dan tidak menyimpan logika bisnis.

Notifier mengatur state loading, data, dan error. Daftar memakai
`campaignListProvider` di
`lib/features/campaign/presentation/providers/campaign_list_provider.dart`
dengan tipe `AsyncNotifier<List<Campaign>>`. Donasi memakai
`donationProvider` di
`lib/features/donation/presentation/providers/donation_providers.dart`
dengan tipe `AsyncNotifier<String?>` yang berisi hash transaksi kalau sukses.

Repository mengatur sumber data. Daftar memakai
`lib/features/campaign/domain/repositories/campaign_repository.dart`
sebagai kontrak dan
`lib/features/campaign/data/repositories/campaign_repository_impl.dart`
sebagai implementasi. Donasi memakai kontrak yang sudah ada di
`lib/features/donation/domain/repositories/donation_repository.dart`
dan implementasi on-chain di
`lib/features/donation/data/repositories/donation_repository_impl.dart`.
Error dikembalikan sebagai `Either<Failure, T>` lalu diubah jadi
`AsyncError` di notifier, supaya UI tinggal menangani lewat `.when`.

## Enam Kondisi UI dan Letaknya

1. Initial loading: `home_screen.dart` bagian `loading` dari `.when`,
   ditambah tombol donasi yang menampilkan spinner saat `isLoading`.
2. Data berhasil dimuat: bagian `data` yang menampilkan `CampaignCard`
   per item, dan dialog hash transaksi setelah donasi sukses.
3. Empty state: bagian `data` yang kosong menampilkan `EmptyStateWidget`.
4. Error dengan retry: bagian `error` menampilkan `ErrorStateWidget`
   dengan tombol Coba Lagi yang memanggil `retry()` di notifier.
   Untuk donasi, pesan error tampil di dalam sheet dan sheet tidak tertutup.
5. Validasi form: `validateDonationAmount` di `donate_bottom_sheet.dart`
   dipakai sebagai `validator` di `TextFormField`. Aturannya: wajib diisi,
   harus angka, harus lebih dari 0, minimal 0,001, dan ada batas atas.
6. Loading submit anti double tap: `PrimaryButton` menonaktifkan
   `onPressed` saat `isLoading` (`lib/core/widgets/primary_button.dart`),
   dan `DonationNotifier.donate` punya guard yang mengabaikan panggilan
   baru selama state masih loading.

## Cara Menjalankan dan Membuktikan

Jalankan `flutter test test/features/donation/campaign_donation_test.dart`
untuk 14 test (5 unit validator, 8 widget, 1 repository).
Jalankan `flutter test` untuk seluruh suite (15 test termasuk smoke test lama).
Jalankan `flutter test --coverage` untuk angka cakupan.

Untuk bukti visual, rekam layar HP fisik dengan urutan: buka Home
(loading lalu daftar), tutup koneksi atau paksa error lalu tekan Coba Lagi,
buka form donasi dan kirim kosong untuk memicu validasi, isi nominal benar
lalu tekan Kirim dua kali cepat untuk menunjukkan tombol terkunci dan
spinner muncul, lalu tunjukkan dialog sukses. Simpan hasilnya di
`screenshots/` dan video singkat di folder ini.

## Status Terakhir

Seluruh 15 test lolos. `flutter analyze` tidak melaporkan masalah di
file-file baru feature ini. Sisanya hanya info lama di file lain.
