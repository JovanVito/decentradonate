# Tugas Pertemuan 5 — MVP Version 1

Dokumen ini mencatat proses iteratif dua fitur inti Decentradonate. Setiap fitur dikerjakan melalui Brief, Plan, Build, Verify, dan Commit.

## Fitur 1 — Donasi Campaign

### Brief

Pengguna harus dapat melihat daftar campaign, membuka detail campaign, mengisi nominal donasi, dan mengirim donasi melalui wallet. Form harus memvalidasi nominal dan mencegah submit ganda.

### Plan

Pisahkan tanggung jawab menjadi:

- Campaign repository dan provider untuk daftar campaign.
- Widget Home dan detail campaign untuk tampilan.
- Donation repository untuk transaksi blockchain.
- Donation notifier untuk state loading, sukses, dan error.
- Form validator untuk nominal donasi.
- Widget test untuk setiap kondisi utama.

### Build

Implementasi utama:

- `lib/features/campaign/presentation/screens/home_screen.dart`
- `lib/features/campaign/presentation/screens/campaign_detail_screen.dart`
- `lib/features/campaign/presentation/providers/campaign_list_provider.dart`
- `lib/features/donation/presentation/widgets/donate_bottom_sheet.dart`
- `lib/features/donation/presentation/providers/donation_providers.dart`
- `lib/features/donation/data/repositories/donation_repository_impl.dart`

### Verify

Acceptance criteria:

- Daftar campaign dapat tampil.
- Loading, loaded, empty, dan error state tersedia.
- Error memiliki tombol retry.
- Nominal kosong, bukan angka, nol, dan nominal terlalu kecil ditolak.
- Saat submit berjalan, tombol disabled dan spinner tampil.
- Double tap hanya menghasilkan satu pemanggilan repository.
- Sukses menampilkan hash transaksi.
- Error transaksi tetap menampilkan form.

Bukti:

- `test/features/donation/campaign_donation_test.dart`
- Lima unit test validator.
- Widget test loading, loaded, empty, error-retry, validasi, submit loading, sukses, dan error.

### Commit

Commit utama fitur:

```text
7da4e6b feat: lengkapi feature donasi campaign untuk tugas state management + 14 test
```

## Fitur 2 — Kontak Wallet dengan Local Persistence

### Brief

Pengguna harus dapat menyimpan alamat wallet favorit secara lokal agar tersedia kembali setelah aplikasi ditutup dan dibuka ulang. Fitur harus menyediakan Create, Read, Update, dan Delete.

### Plan

- Buat storage abstraction yang mendukung SQLite di Android dan localStorage melalui `shared_preferences` di web.
- Buat model `WalletContact`.
- Pisahkan kontrak repository dari implementasi storage.
- Kelola state daftar kontak memakai Riverpod `AsyncNotifier`.
- Tambahkan UI tambah, edit, hapus, dan daftar kontak di Wallet.
- Tambahkan test CRUD dan simulasi aplikasi dibuka kembali.

### Build

Implementasi utama:

- `lib/core/database/local_store.dart`
- `lib/core/database/platform_io.dart`
- `lib/core/database/platform_web.dart`
- `lib/features/wallet/domain/entities/wallet_contact.dart`
- `lib/features/wallet/domain/repositories/contact_repository.dart`
- `lib/features/wallet/data/repositories/contact_repository_impl.dart`
- `lib/features/wallet/presentation/providers/contact_providers.dart`
- `lib/features/wallet/presentation/widgets/contact_section.dart`
- `lib/features/wallet/presentation/screens/wallet_screen.dart`

Android memakai file SQLite `decentradonate.db`. Chrome memakai `shared_preferences` yang tersimpan melalui localStorage karena `sqflite` tidak tersedia di web.

### Verify

Acceptance criteria:

- Create menyimpan kontak baru.
- Read menampilkan kontak tersimpan.
- Update mengubah nama kontak.
- Delete menghapus kontak.
- Data tetap tersedia setelah provider dibuat ulang, sebagai simulasi aplikasi ditutup dan dibuka kembali.
- Data model dapat dikonversi ke Map dan dikembalikan lagi tanpa kehilangan nilai.
- Android dan Chrome memiliki storage backend yang sesuai platform.

Bukti:

```text
flutter test test/features/wallet/contact_persistence_test.dart
5 tests passed
```

Test full project:

```text
flutter test
20 tests passed
```

Demo manual:

1. Wallet → Tambah kontak.
2. Isi nama dan alamat wallet.
3. Tutup aplikasi atau refresh Chrome.
4. Buka Wallet dan pastikan kontak masih ada.
5. Edit nama.
6. Hapus kontak.

### Commit

Commit fitur akan dibuat setelah verifikasi:

```text
feat: tambah CRUD kontak wallet dengan local persistence
```

## Peran AI Agent dan Review Mahasiswa

AI Agent membantu membuat draft struktur provider, repository, model, UI, dan test berdasarkan brief. Mahasiswa memeriksa struktur project, menyesuaikan kode dengan Riverpod dan Clean Architecture, menambahkan fallback web, memperbaiki validasi, menjalankan test, serta memastikan data flow dapat dijelaskan.

AI tidak diminta membuat seluruh aplikasi sekaligus. Pengerjaan dilakukan per fitur dengan acceptance criteria yang terpisah.
