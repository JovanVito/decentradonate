# Arsitektur Donasi Transparan

## Tujuan
Aplikasi Flutter + Supabase membantu penggalang dana menerbitkan campaign, menerima donasi, dan menunjukkan bukti penyaluran berbasis foto dan GPS.

## Struktur

```text
lib/
├── main.dart                 # bootstrap Supabase, auth, navigasi utama
├── campaign.dart             # daftar, pembuatan, detail campaign, donasi, bukti
├── wallet_community.dart     # dompet dan komunitas
├── local_repository.dart     # model LocalNote dan CRUD SharedPreferences
└── local_notes.dart          # state controller dan UI catatan lokal
supabase_schema.sql           # tabel, RPC, RLS, storage policy
```

## Vertical slice: Catatan lokal

`LocalNotesPage` membaca state dari `LocalNotesController`. Controller memanggil `LocalNoteRepository`; repository menyimpan `LocalNote` sebagai JSON di `SharedPreferences`.

Alur: UI -> controller -> repository -> SharedPreferences.

State yang diterapkan: loading awal, data berhasil, empty, error + retry, validasi form, dan loading submit untuk mencegah double tap. CRUD: tambah, baca, edit, hapus. Data bertahan setelah aplikasi dibuka ulang atau browser di-refresh.

## Integrasi backend

Campaign, donasi, auth, dompet, komunitas, dan bukti memakai Supabase. `supabase_schema.sql` menjadi kontrak data dan RPC. UI membaca data saat halaman dimuat atau refresh manual; aksi tulis memakai insert/RPC lalu reload.

## Fitur lanjutan

- Autentikasi email Supabase.
- Kamera untuk foto bukti penyaluran.
- Lokasi GPS dan penolakan mock GPS.

## Risiko

Izin kamera/lokasi dapat ditolak. Upload bukti berhenti dan menampilkan pesan. Foto bukti dan koordinat tersimpan pada Supabase Storage/database; production wajib meninjau RLS dan kebijakan privasi.

## Catatan implementasi

State management saat ini memakai `ChangeNotifier` dengan tanggung jawab terpisah antara widget, controller, dan repository. `flutter_riverpod` sudah tersedia untuk migrasi provider berikutnya, tetapi vertical slice aktif memakai controller lokal agar sederhana dan mudah diuji.
