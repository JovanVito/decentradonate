# Catatan Tahapan Iteratif MVP

Dokumen ini mencatat dua commit meaningful yang membentuk MVP Version 1.

## Commit 1 — Donasi Campaign

```text
7da4e6b feat: lengkapi feature donasi campaign untuk tugas state management + 14 test
```

Brief: user dapat melihat campaign dan berdonasi.

Plan: repository + Riverpod notifier + form validation + anti double-submit.

Build: campaign list, detail, donation bottom sheet, repository, notifier, dan test.

Verify: loading, loaded, empty, error-retry, validasi, submit loading, sukses, dan error diuji.

## Commit 2 — Local Contacts

```text
6a3af0b feat: tambah CRUD kontak wallet dengan local persistence
```

Brief: user dapat menyimpan alamat wallet favorit secara lokal.

Plan: model + repository CRUD + storage native/web + Riverpod + UI + persistence test.

Build: `WalletContact`, `ContactRepository`, `LocalStore`, `ContactNotifier`, dan `ContactSection`.

Verify: 5 test kontak untuk create, read, update, delete, dan provider reopen. Full suite berisi 20 test dan semuanya lulus.

## Acceptance Criteria MVP

- Aplikasi runnable.
- Dua fitur inti tersedia.
- Minimal dua meaningful commit tersedia.
- Test file tersedia.
- Acceptance criteria dapat didemokan secara manual.
- AI membantu draft/scaffold, mahasiswa memeriksa, menyesuaikan, menjalankan, dan menjelaskan kode.
