# Decentradonate

Aplikasi donasi mikro terdesentralisasi (Flutter + Polygon Amoy Testnet)
dengan Proof-of-Impact via Kamera, GPS, dan IPFS.

---

## 1. Deskripsi Masalah

Penggalangan dana daring (donasi mikro) melalui platform konvensional
(mis. GoFundMe, KitaBisa, dan sejenisnya) menghadapi tiga masalah utama:

1. **Minim transparansi penyaluran dana.** Donatur tidak punya cara
   independen untuk memverifikasi bahwa dana yang mereka kirim benar-benar
   sampai dan dipakai sesuai tujuan kampanye. Semua catatan transaksi
   berada di database privat milik platform.
2. **Ketergantungan pada perantara terpusat.** Platform konvensional
   mengambil potongan biaya administrasi, dan seluruh proses (verifikasi,
   pencairan dana) bergantung penuh pada kebijakan internal satu entitas
   — donatur dan organizer sama-sama tidak punya kendali atas prosesnya.
3. **Tidak ada bukti fisik penggunaan dana yang terstruktur.** Setelah
   dana cair, sangat jarang platform menyediakan mekanisme baku untuk
   organizer membuktikan dana benar-benar dipakai (foto lokasi, waktu,
   dan konteks penggunaan) secara mudah dan terverifikasi.

**Decentradonate** menjawab ketiga masalah ini dengan mencatat setiap
donasi langsung di blockchain publik (transparan & tidak bisa diubah),
serta mewajibkan organizer mengunggah **Proof-of-Impact** (foto + lokasi
GPS, disimpan permanen di IPFS) sebagai bukti penggunaan dana.

---

## 2. Profil Target Pengguna

Karena aplikasi ini dibangun di atas **Polygon Amoy Testnet** untuk
keperluan tugas akhir mata kuliah, target pengguna di bawah ini adalah
profil yang disasar **secara konsep produk** — bukan pengguna produksi
sungguhan selama masa pengembangan 12 minggu.

| Persona | Kebutuhan Utama |
|---|---|
| **Donatur melek teknologi** — individu berusia 20–40 tahun yang terbiasa dengan aplikasi digital dan skeptis terhadap transparansi platform donasi konvensional | Ingin memastikan donasinya sampai dan dipakai sesuai tujuan; nyaman memakai wallet kripto sederhana |
| **Organizer/penggalang dana skala kecil–menengah** — individu atau komunitas (mis. relawan bencana lokal, kelompok swadaya masyarakat) yang butuh dana cepat tanpa proses administrasi platform besar | Butuh kanal penggalangan dana yang mudah dibuat, minim birokrasi, dan bisa membuktikan penggunaan dana dengan gampang lewat kamera HP |
| **Peninjau/auditor independen** (termasuk dosen penguji dalam konteks tugas ini) | Ingin memverifikasi transaksi secara independen lewat block explorer publik, tanpa perlu akses khusus ke sistem manapun |

---

## 3. Manfaat Aplikasi

- **Transparansi permanen** — setiap donasi tercatat sebagai transaksi
  di Polygon (dapat diverifikasi siapa pun lewat PolygonScan), tidak
  bisa diubah atau disembunyikan setelah tercatat.
- **Minim perantara** — dana dari donatur diteruskan langsung ke wallet
  organizer melalui smart contract, tanpa proses pencairan manual yang
  bergantung pada kebijakan internal platform.
- **Akuntabilitas terstruktur** — kewajiban unggah Proof-of-Impact
  (foto + GPS) memberi donatur bukti visual dan lokasional atas
  penggunaan dana, tersimpan permanen di IPFS (tidak bisa dihapus
  sepihak oleh siapa pun, termasuk pembuat aplikasi).
- **Kepemilikan penuh oleh pengguna (self-custody)** — wallet dibuat
  dan disimpan di perangkat pengguna sendiri, bukan dikelola akun
  terpusat milik platform.
- **Biaya rendah** — tanpa potongan admin platform; biaya yang ada
  hanya gas fee jaringan blockchain (di testnet, ini gratis).

---

## 4. Daftar Fitur Inti (Realistis Diselesaikan dalam 12 Pertemuan)

Fitur ini dipetakan langsung ke 4 fase silabus (Define → Build Core →
Harden → Release):

1. **Manajemen Wallet** — generate wallet baru (mnemonic 12 kata) atau
   import wallet yang sudah ada, disimpan terenkripsi di perangkat.
2. **Daftar & Detail Kampanye** — menampilkan kampanye donasi beserta
   progres pengumpulan dana, dibaca langsung dari smart contract.
3. **Donasi On-Chain** — transfer MATIC (testnet) ke kampanye pilihan
   lewat smart contract, dengan status transaksi (pending/sukses/gagal)
   ditampilkan jelas ke pengguna.
4. **Proof-of-Impact** — organizer mengambil foto + menandai lokasi GPS
   sebagai bukti penggunaan dana, diunggah ke IPFS.
5. **Riwayat Transaksi** — daftar donasi yang pernah dilakukan/diterima,
   diambil dari event on-chain.
6. **Loading, Empty, dan Error State** di setiap alur utama — termasuk
   penanganan kondisi jaringan lambat/terputus dan konfigurasi yang
   belum lengkap, tanpa fatal crash.
7. **APK Rilis** — dapat diinstal dan didemonstrasikan di perangkat
   Android fisik.

---

## 5. Fitur yang Tidak Dikerjakan (Out of Scope)

Ditetapkan secara sadar di awal supaya scope tetap realistis untuk 12
minggu pengerjaan solo/tim kecil:

- **Tidak ada backend/server custom.** Seluruh data bersumber dari
  blockchain (on-chain) dan IPFS — tidak ada REST API atau database
  server yang dikelola sendiri.
- **Tidak ada derivasi wallet BIP-44 penuh** yang kompatibel dengan
  MetaMask/Trust Wallet — wallet dibuat dan dipakai sepenuhnya mandiri
  di dalam aplikasi ini.
- **Tidak ada dukungan mainnet/produksi.** Aplikasi tetap berjalan di
  Polygon Amoy Testnet selama masa pengembangan dan demo.
- **Tidak ada sistem KYC/verifikasi identitas** organizer maupun donatur.
- **Tidak ada mekanisme approval/withdrawal request** — donasi
  diteruskan otomatis dan langsung oleh smart contract ke organizer.
- **Tidak ada dukungan multi-token/multi-currency** — hanya native
  token MATIC (testnet) yang didukung.
- **Tidak ada notifikasi push.**
- **Tidak ada dukungan multi-bahasa (i18n)** — aplikasi hanya berbahasa
  Indonesia.
- **Tidak ada fitur sosial** (komentar, like, share antar-pengguna di
  dalam aplikasi) pada kampanye.
- **Tidak ada dashboard admin/analitik** di luar apa yang bisa dilihat
  langsung dari block explorer publik.
- **Tidak ada build/testing untuk iOS** — pengembangan dan pengujian
  difokuskan penuh pada Android sesuai konteks tugas.

---

## 6. Kriteria Aplikasi Dinyatakan Berhasil

Aplikasi dianggap **berhasil** memenuhi tujuan tugas akhir bila seluruh
poin berikut terpenuhi pada demo Checkpoint Offline 4 (Final):

1. **APK terinstal dan berjalan** di perangkat Android fisik tanpa
   dependency ke emulator maupun lingkungan development.
2. **Alur utama (vertical slice) berjalan end-to-end**: pengguna dapat
   membuat/import wallet → melihat daftar kampanye → memilih satu
   kampanye → melakukan donasi → transaksi berhasil terverifikasi di
   blockchain (dapat ditunjukkan lewat PolygonScan Amoy).
3. **Setiap layar utama** (Home, Detail, Wallet, Upload Proof)
   menampilkan Loading, Empty, dan Error state yang sesuai konteks —
   tidak ada layar kosong/putih tanpa penjelasan saat data belum ada
   atau gagal dimuat.
4. **Tidak ada fatal crash** saat kondisi jaringan lambat, terputus,
   atau konfigurasi (RPC/contract) belum lengkap — aplikasi selalu
   menampilkan pesan yang informatif.
5. **Fitur Proof-of-Impact berfungsi**: foto dan lokasi GPS berhasil
   diambil dan diunggah ke IPFS, dengan bukti (hash/link) dapat diakses.
6. **Source code terorganisir** mengikuti Clean Architecture yang
   didokumentasikan di `STRUCTURE.md`, dan mahasiswa dapat menjelaskan
   alasan setiap keputusan desain saat ditanya dosen penguji.
7. **Riwayat commit Git** menunjukkan progres bertahap yang bermakna
   (bukan satu commit besar di akhir), selaras dengan timeline 12 minggu.
8. **Lolos seluruh 4 checkpoint offline** sesuai jadwal yang ditetapkan
   dosen (Define, UTS Vertical Slice, Harden/peer-review, Final Release).

---
