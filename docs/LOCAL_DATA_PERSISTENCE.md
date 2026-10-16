# Local Data & Persistence — Kontak Wallet

Dokumen ini menjelaskan implementasi Local Data & Persistence pada project
Decentradonate dan posisi kodenya, supaya mudah ditunjukkan saat review.

## Kenapa Ada Dua Database?

Project ini memakai dua lapis penyimpanan dengan peran berbeda:

- **Supabase (cloud)** — akun, profil, role organizer, metadata proof.
  Dipilih karena data ini harus bisa diakses lintas perangkat.
- **SQLite lokal (`sqflite`)** — data pribadi yang harus tetap ada walau
  perangkat offline, dan aksesnya harus instan.

Fitur yang dipakai sebagai bukti Local Data & Persistence adalah
**Kontak Wallet**: daftar alamat wallet favorit milik pengguna.

## Posisi Kode

```text
lib/
├── core/
│   └── database/
│       ├── local_store.dart                   <- storage abstraction
│       ├── platform_io.dart                   <- backend native
│       └── platform_web.dart                  <- backend web
└── features/wallet/
    ├── domain/
    │   ├── entities/wallet_contact.dart       <- Data Model
    │   └── repositories/contact_repository.dart <- kontrak CRUD
    ├── data/
    │   └── repositories/contact_repository_impl.dart <- query SQL (CRUD)
    └── presentation/
        ├── providers/contact_providers.dart   <- state CRUD (Riverpod)
        └── widgets/contact_section.dart       <- UI CRUD

test/features/wallet/contact_persistence_test.dart  <- test CRUD + persistensi
```

## Data Model

`WalletContact`: `id` (int, auto increment), `name` (string),
`address` (string, format `0x…`), `addedAt` (DateTime, disimpan sebagai
milidetik). Konversi ke/dari SQLite ada di `toMap()` dan `fromMap()`.

## Pemetaan CRUD

| Operasi | Kode |
|---|---|
| Create | `ContactRepositoryImpl.insertContact()` / `ContactNotifier.addContact()` |
| Read | `ContactRepositoryImpl.getContacts()` / `ContactNotifier.build()` |
| Update | `ContactRepositoryImpl.updateContact()` / `ContactNotifier.editContact()` |
| Delete | `ContactRepositoryImpl.deleteContact()` / `ContactNotifier.removeContact()` |

Semua error database dikembalikan sebagai nilai `CacheFailure` lewat
`Either<Failure, T>`, bukan exception yang melempar crash ke UI.

## Alur Data (vertikal, FE → Local Storage)

```text
ContactSection (UI)
  -> ref.read(contactProvider.notifier).addContact(...)
ContactNotifier (AsyncNotifier)
  -> ref.read(contactRepositoryProvider).insertContact(...)
ContactRepositoryImpl        (menulis query SQL)
  -> LocalStore (SQLite di Android / localStorage di Chrome)
  <- Either<Failure, WalletContact>
  <- state diperbarui dari hasil getContacts()
UI render ulang daftar kontak
```

## Bukti Persistensi

Pada Android, data disimpan di file SQLite `decentradonate.db` pada folder dokumen aplikasi. Pada Chrome, data disimpan melalui `shared_preferences` yang menggunakan localStorage. Keduanya bukan state widget sementara dan tetap tersedia setelah aplikasi dibuka kembali atau browser di-refresh.

Demo 1 menit:
1. Buka tab Wallet, tekan **Tambah**, isi nama dan alamat, simpan.
2. Tutup paksa aplikasi (Recents → swipe) atau jalankan ulang dari HP.
3. Buka lagi tab Wallet → kontak tadi masih ada (READ dari disk).
4. Ubah nama kontak (UPDATE), lalu hapus (DELETE).

Uji otomatis: `flutter test test/features/wallet/contact_persistence_test.dart`
memverifikasi CREATE, READ, UPDATE, DELETE, plus skenario "tutup lalu buka"
yang meniru aplikasi dijalankan kembali.

## Persiapan Perkembangan Selanjutnya

- `LocalStore` memusatkan akses storage. Untuk SQLite, versi database dan migrasi dapat ditambahkan saat schema berkembang. Untuk web, key storage dapat dipisahkan per fitur tanpa menyentuh UI.
- Karena CRUD dipisah dalam repository, penggantian engine (mis. ke Isar/Hive)
  cukup membuat `ContactRepositoryImpl` versi baru tanpa menyentuh UI.
- Pola ini bisa dipakai ulang untuk cache campaign, draft proof-of-impact,
  atau pengaturan aplikasi.
