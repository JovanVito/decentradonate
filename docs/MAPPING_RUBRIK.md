# Kesesuaian Struktur Proyek dengan Kebutuhan Progress

Dokumen ini dibuat untuk menjelaskan posisi proyek Decentradonate terhadap
kebutuhan progress mata kuliah. Strukturnya memang tidak sama persis dengan
contoh yang diberikan, tapi secara isi sudah mencakup semuanya. Perbedaannya
hanya di penamaan folder karena proyek ini memakai Clean Architecture
dengan pendekatan feature-first.

## 1. Posisi Setiap Kebutuhan

Kebutuhan pertama adalah prototype. Di proyek ini prototype-nya berupa tampilan
Flutter yang sudah bisa dijalankan, yaitu halaman Home sebagai dashboard,
halaman Detail kampanye, halaman Wallet, dan halaman Upload Bukti. File-nya ada di
`lib/features/campaign/presentation/screens/home_screen.dart` untuk dashboard,
`campaign_detail_screen.dart` untuk detail, `lib/features/wallet/presentation/screens/wallet_screen.dart`
beserta `import_wallet_screen.dart` dan `backup_mnemonic_screen.dart` untuk bagian
wallet, serta `lib/features/proof_of_impact/presentation/screens/upload_proof_screen.dart`
untuk upload bukti. Jadi semua alur utama sudah bisa didemokan langsung di HP.

Kebutuhan kedua adalah struktur proyek. Contoh di soal memisahkan halaman,
widget, model, service, dan routing. Proyek ini melakukan hal yang sama,
hanya saja dikelompokkan per fitur. Halaman ada di `features/*/presentation/screens`,
widget yang dipakai berulang ada di `lib/core/widgets` dan di
`features/*/presentation/widgets`, model data ada di `features/*/domain/entities`
dengan nama seperti `campaign.dart` dan `wallet_info.dart`, service ada di
`lib/services` seperti `wallet_service.dart` dan `web3_service.dart` ditambah
repository di `features/*/data/repositories`. Routing ada di
`lib/core/router/app_router.dart` dan `app_shell.dart`.

Kebutuhan ketiga adalah routing. Perpindahan halaman sudah diatur memakai
go_router dengan StatefulShellRoute. Bottom navigation untuk Home, Wallet,
dan Upload Proof dibuat persisten sehingga pindah tab tidak mengulang state.
Halaman detail memakai rute `/campaign/:id` sehingga bisa dibuka lewat deep link,
dan data campaign dikirim lewat `extra` supaya tidak perlu fetch ulang.

Kebutuhan keempat adalah reusable component. Komponen yang dipakai berulang
sudah dipisah, antara lain `primary_button.dart`, `loading_widget.dart`,
`empty_state_widget.dart`, `error_state_widget.dart`, dan `app_bottom_nav.dart`
di `lib/core/widgets`, ditambah `campaign_card.dart` dan `donate_bottom_sheet.dart`
di masing-masing fitur. Setiap layar utama juga sudah punya kondisi loading,
kosong, dan error.

Entry point dan root widget juga sudah sesuai contoh, yaitu `lib/main.dart`
yang berisi ProviderScope dan `lib/app.dart` yang berisi MaterialApp.router.

## 2. Hal yang Perlu Dijelaskan Saat Presentasi

Ada dua hal yang biasanya ditanyakan karena namanya tidak sama dengan contoh.

Pertama, proyek ini tidak punya halaman login username dan password.
Alasannya karena sejak awal sudah ditetapkan tidak ada backend dan tidak ada
akun terpusat. Penggantinya adalah wallet. Alur create wallet, backup 12 kata,
dan import wallet di tab Wallet itu yang menjadi pengganti login. Penjelasan
lengkap soal batasan ini ada di PROJECT_DEFINITION bagian Out of Scope.

Kedua, proyek ini tidak punya file profile tersendiri. Fungsinya digabung ke
halaman Wallet, yaitu menampilkan alamat wallet, saldo, dan tombol backup
mnemonic. Jadi kalau diminta menunjukkan profile, yang dibuka adalah tab Wallet.

## 3. Alur Demo yang Disarankan

Untuk menunjukkan bahwa semua kebutuhan sudah terpenuhi, urutan demo yang
paling mudah adalah sebagai berikut. Pertama jalankan aplikasi di HP fisik
dan buka tab Home, lalu scroll daftar kampanye. Kedua buka salah satu campaign
untuk masuk ke halaman detail, lalu buka bottom sheet donasi. Ketiga pindah-pindah
tab Home, Wallet, dan Upload Proof untuk menunjukkan state tidak hilang.
Keempat buka menu titik tiga di app bar Home untuk menunjukkan kondisi loading,
empty, dan error. Kelima buka tab Wallet dan tunjukkan proses buat wallet sampai
ke halaman backup mnemonic.

## 4. Catatan Tambahan untuk Pertanyaan Dosen

Pemisahan domain, data, dan presentation sengaja dibuat supaya perubahan di satu
bagian tidak merambat ke bagian lain. Misalnya kalau RPC diganti, yang berubah
hanya service dan repository, aturan bisnis di domain dan tampilan tidak ikut
berubah. Aturannya domain tidak boleh import dari data atau presentation.

Pemilihan go_router dengan StatefulShellRoute alasannya untuk deep link dan
navigasi bawah yang tetap hidup. Pemilihan ViewState dengan sealed class
alasannya supaya semua kondisi (initial, loading, loaded, empty, error) wajib
ditangani dan tidak ada yang terlewat. Mnemonic tidak disimpan di state provider
setelah dibuat, hanya dikembalikan sekali dan dikirim ke halaman backup supaya
jejaknya seminimal mungkin. Data di Home masih dummy karena fokus tahap awal
adalah routing dan UI, sinkronisasi penuh dari contract menjadi pekerjaan lanjutan.
ID dummy memakai 0, 1, 2 supaya selaras dengan index array di smart contract
untuk keperluan uji donasi.

Dokumen pendukung lain yang bisa dibuka saat presentasi adalah STRUCTURE.md
untuk alasan arsitektur, Architecture.md untuk gambaran menyeluruh, dan
PROJECT_DEFINITION.md bagian 4 sampai 6 untuk daftar fitur dan kriteria lulus.
