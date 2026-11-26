# Product Requirements Document

## Nama produk

Donasi Transparan

## Ringkasan

Donasi Transparan adalah aplikasi Flutter yang menghubungkan penggalang dana dan donatur. Penggalang dana membuat campaign, menetapkan target dan alokasi, menerima donasi, lalu mengunggah bukti penyaluran berupa foto dan koordinat GPS. Donatur melihat perkembangan campaign, transaksi, alokasi dana, dan bukti penyaluran.

## Masalah

Informasi campaign, transaksi donasi, rencana alokasi, dan bukti penyaluran sering tersebar. Donatur sulit memeriksa perkembangan dana serta bukti penggunaan dana.

## Target pengguna

1. Penggalang dana yang membuat dan mengelola campaign.
2. Donatur yang menyumbang dan memantau campaign.
3. Anggota komunitas yang berdiskusi tentang campaign sosial.

## Tujuan MVP

- Pengguna dapat mendaftar dan masuk dengan email.
- Penggalang dana dapat membuat campaign dan alokasi dana.
- Donatur dapat melihat campaign dan melakukan donasi dari saldo.
- Pemilik campaign dapat mengakhiri campaign.
- Pemilik campaign dapat mengunggah bukti penyaluran dengan kamera dan GPS.
- Pengguna dapat membuat, membaca, mengubah, dan menghapus catatan lokal.
- Data penting tersimpan di Supabase.

## Di luar ruang lingkup MVP

- Payment gateway produksi.
- Notifikasi push.
- Panel admin.
- Multi-role authorization yang lengkap.
- Moderasi konten otomatis.
- Chat privat.
- Grafik analitik.
- Publikasi Play Store.

## Alur utama

### Autentikasi

1. Pengguna membuka aplikasi.
2. Pengguna memilih masuk atau daftar.
3. Supabase Auth memproses email dan password.
4. Trigger database membuat profile pengguna.
5. Pengguna masuk ke halaman utama.

### Membuat campaign

1. Pengguna membuka menu Campaign.
2. Pengguna memilih `Galang Dana`.
3. Pengguna mengisi judul, deskripsi, target, dan alokasi.
4. Total alokasi harus sama dengan target.
5. Aplikasi menyimpan campaign dan alokasi ke Supabase.
6. Campaign muncul pada daftar campaign.

### Donasi

1. Donatur membuka detail campaign aktif.
2. Donatur memasukkan nominal.
3. Aplikasi memanggil RPC `donate`.
4. RPC mengurangi saldo donatur, menambah dana campaign, dan menyimpan transaksi.
5. Aplikasi memuat ulang detail campaign.

### Bukti penyaluran

1. Pemilik mengakhiri campaign.
2. Pemilik memilih `Unggah Bukti`.
3. Aplikasi meminta izin kamera dan lokasi.
4. Aplikasi mengambil foto dari kamera.
5. Aplikasi mengambil lokasi terbaru.
6. Aplikasi menolak lokasi mock GPS.
7. Foto disimpan ke Storage bucket `proofs`.
8. Metadata bukti disimpan ke tabel `proofs`.

### Catatan lokal

1. Pengguna membuka menu Catatan.
2. Aplikasi memuat catatan dari `SharedPreferences`.
3. Pengguna menambah, mengubah, atau menghapus catatan.
4. Aplikasi menampilkan loading, empty, error, retry, validasi, dan submit loading.
5. Catatan tetap tersedia setelah aplikasi dibuka ulang.

## Arsitektur teknis

- Client: Flutter dan Dart.
- Backend: Supabase.
- Database: PostgreSQL melalui Supabase.
- Auth: Supabase Auth email.
- Penyimpanan file: Supabase Storage.
- State management vertical slice: `ChangeNotifier`.
- Local persistence: `SharedPreferences`.
- Integrasi data: Supabase client dan RPC PostgreSQL.
- Model lokal: `LocalNote`.

```text
UI Flutter
├── AuthPage
├── Home
├── CampaignList / CreateCampaign / CampaignDetail
├── WalletPage
├── CommunityPage
└── LocalNotesPage
    └── LocalNotesController
        └── LocalNoteRepository
            └── SharedPreferences

Supabase Client
├── Auth
├── PostgreSQL tables
├── RPC functions
└── Storage bucket proofs
```

## Struktur kode

```text
lib/
├── main.dart
├── campaign.dart
├── wallet_community.dart
├── local_notes.dart
└── local_repository.dart
supabase_schema.sql
Architecture.md
SUPABASE_SETUP.md
test/widget_test.dart
```

## Kriteria penerimaan

- Aplikasi dapat dibangun dengan `flutter build apk --release`.
- Test berjalan dengan `flutter test`.
- Aplikasi tidak memulai jika URL atau publishable key Supabase tidak tersedia.
- Pengguna dapat daftar, masuk, dan keluar.
- Profile otomatis dibuat setelah pendaftaran.
- Campaign dan alokasi tersimpan di Supabase.
- Validasi total alokasi sama dengan target.
- Donasi memakai RPC dan tidak menulis transaksi langsung dari client.
- Campaign dapat diakhiri oleh pemilik.
- Bukti hanya dapat dibuat pemilik setelah campaign berakhir.
- Bukti menyimpan foto, catatan, latitude, longitude, dan waktu.
- Mock GPS ditolak.
- Catatan lokal memiliki CRUD dan bertahan setelah restart.
- Loading, empty, error, retry, validasi, dan submit loading tampil pada fitur catatan.
- RLS mencegah akses tulis yang tidak sesuai.
- Tidak ada `service_role` key di source code atau APK.

## Pengujian wajib

### Unit test

- Serialisasi `LocalNote`.
- Deserialisasi `LocalNote`.
- Validasi judul kosong.
- Validasi isi kosong.
- Create catatan.
- Update catatan.
- Delete catatan.

### Pengujian manual

- Daftar pengguna baru.
- Masuk dan keluar.
- Membuat campaign dengan alokasi valid.
- Menolak alokasi yang jumlahnya tidak sama dengan target.
- Donasi dengan saldo cukup.
- Donasi dengan saldo tidak cukup.
- Mengakhiri campaign.
- Menolak upload bukti sebelum campaign berakhir.
- Upload bukti dengan kamera dan GPS.
- Menolak izin kamera.
- Menolak izin lokasi.
- Menolak mock GPS.
- CRUD catatan.
- Restart aplikasi dan memastikan catatan tetap ada.
- Layout layar kecil dan besar.
- Keyboard tidak menutup field aktif.

## Pekerjaan tersisa untuk agent

1. Menjalankan `supabase_schema.sql` pada project Supabase nyata.
2. Mengisi URL dan publishable key melalui `--dart-define`.
3. Menguji auth dan seluruh query terhadap database nyata.
4. Meninjau ulang RLS, terutama pembacaan data donasi dan profil.
5. Memperbaiki RPC `donate` agar saldo tidak dapat menjadi negatif.
6. Menghapus atau mengamankan fungsi top up demo sebelum produksi.
7. Menambah test controller untuk semua state utama.
8. Menambah widget test untuk loading, success, empty, error, retry, validasi, dan submit loading.
9. Menguji permission kamera dan lokasi pada Android nyata.
10. Menguji upload Storage dengan policy yang aktif.
11. Menangani error FutureBuilder secara eksplisit pada campaign, wallet, dan komunitas.
12. Menghapus file Dart duplikat di root jika tidak diperlukan; source utama harus berada di `lib/`.
13. Mengganti `anonKey` lama pada semua file tersisa jika masih ada.
14. Menambahkan logging terstruktur tanpa mencetak token atau data sensitif.
15. Menjalankan audit dependensi dan build release.
16. Membuat minimal 10 issue GitHub, termasuk minimal 5 bug hasil pengujian nyata.
17. Membuat bukti screenshot atau video untuk state management, persistence, layout, accessibility, dan feedback aksi.
18. Membuat checklist release dan menguji instalasi APK pada device.

## Batas keamanan

- Gunakan publishable key saja di Flutter.
- Jangan gunakan `service_role` key di client.
- Jangan mencetak token, password, atau data pribadi ke log.
- Review RLS sebelum deployment.
- Validasi nominal donasi di database, bukan hanya di UI.
- Gunakan payment gateway server-side untuk top up produksi.
- Audit akses Storage bucket `proofs` sebelum menjadikannya publik.
