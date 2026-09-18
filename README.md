# Decentradonate

Aplikasi donasi mikro terdesentralisasi (Flutter + Polygon Amoy Testnet)
dengan Proof-of-Impact via Kamera, GPS, dan IPFS.

## Status: Stage 2.3 — Fungsi Donasi On-Chain

**Baru ditambahkan:**
- `DonationRepository` (domain) + `DonationRepositoryImpl` (data) —
  sign & kirim transaksi `donate(campaignId)` ke smart contract
- `DonationNotifier` — state idle/loading/sukses(txHash)/error
- `DonateBottomSheet` — UI input nominal, keyboard-safe, dialog sukses
  dengan hash transaksi yang bisa disalin
- `walletServiceProvider`/`web3ServiceProvider` dipindah ke
  `core/providers/` supaya bisa dipakai bersama fitur `wallet` & `donation`
- `blockchain/DEPLOY_GUIDE.md` Langkah 7 — cara membuat campaign pertama
  di contract via Remix, supaya donasi punya target yang valid

**Status Vertical Slice (requirement checkpoint UTS):** kode untuk alur
"input donasi → transaksi tercatat di blockchain" SUDAH LENGKAP.
Yang tersisa murni tugas konfigurasi eksternal kamu (deploy contract +
Alchemy key), BUKAN tugas coding lagi, untuk fitur donasi dasar ini.

### Aksi Kamu Sekarang

1. Test di HP fisik: masuk Detail Kampanye → Donasi Sekarang → isi
   nominal → kirim → pastikan muncul pesan "Konfigurasi Blockchain
   Belum Lengkap" (bukan crash) — SAMA seperti balance check di 2.2
2. Commit:
   ```bash
   git commit -am "feat: implement on-chain donation flow via web3dart sendTransaction"
   ```
3. Selesaikan `blockchain/DEPLOY_GUIDE.md` (termasuk Langkah 7 yang baru)
4. Setelah kredensial & campaign pertama siap, test ulang alur donasi
   end-to-end dan verifikasi hash transaksi muncul di PolygonScan Amoy —
   ini yang akan kamu tunjukkan saat checkpoint UTS

## Status Sebelumnya: Stage 2.2 — Integrasi Web3 (Baca Saldo)

**Baru ditambahkan:**
- `Web3Service` — singleton koneksi `Web3Client` ke Alchemy RPC
- `WalletRepository.getBalance()` — baca saldo MATIC sebuah address
- `walletBalanceProvider` — auto-fetch saldo saat tab Wallet dibuka + tombol Refresh
- Deteksi konfigurasi belum lengkap → pesan error yang JELAS (bukan crash)
  mengarahkan ke `blockchain/DEPLOY_GUIDE.md`

**PENTING:** kredensial (RPC URL, contract address, ABI) MASIH placeholder
sesuai konfirmasimu — kode ini didesain supaya tetap bisa di-test SEKARANG
tanpa kredensial (akan menampilkan Error state "Konfigurasi Belum
Lengkap" yang informatif), dan begitu kredensial nyata diisi, kode yang
SAMA langsung berfungsi tanpa perlu diubah.

### Aksi Kamu Sekarang

1. Test di HP fisik: buka tab Wallet, pastikan muncul pesan
   "Konfigurasi Blockchain Belum Lengkap" (bukan crash/freeze)
2. Commit:
   ```bash
   git commit -am "feat: integrate web3dart for balance checking with config-aware error handling"
   ```
3. Lanjutkan proses deploy contract & setup Alchemy sesuai
   `blockchain/DEPLOY_GUIDE.md` kapan pun kamu sudah punya akses/waktu
4. Setelah kredensial terisi, buka lagi tab Wallet dan tekan Refresh —
   seharusnya saldo asli (0 MATIC kalau wallet baru) langsung muncul
   TANPA perlu saya ubah kode apa pun

## Status Sebelumnya: Stage 2.1 — Wallet (Minggu 4, bagian dari Build Core Experience)

**Baru ditambahkan dari Stage 1:**
- Wallet generate baru (12 kata BIP-39) + layar backup seed phrase wajib konfirmasi
- Import wallet dari mnemonic yang sudah ada
- Penyimpanan mnemonic terenkripsi via `flutter_secure_storage`
- State wallet dikelola Riverpod `AsyncNotifier` (loading/error/data otomatis)
- Smart contract Solidity (`blockchain/Decentradonate.sol`) + panduan deploy
  gratis ke Polygon Amoy Testnet (`blockchain/DEPLOY_GUIDE.md`)

**Belum ada (menyusul Langkah 2.2 & 2.3):**
- Baca saldo wallet dari blockchain (perlu web3dart + Alchemy)
- Fungsi donasi nyata (transfer MATIC ke smart contract)
- Sinkronisasi daftar campaign dari on-chain data

### PENTING — Aksi Kamu Sebelum Lanjut ke Langkah 2.2

1. Ikuti `blockchain/DEPLOY_GUIDE.md` untuk deploy smart contract ke
   Polygon Amoy Testnet (gratis, ±15-20 menit)
2. Test fitur wallet di HP fisik: buat wallet baru → catat seed phrase →
   hapus wallet → import lagi pakai seed phrase yang sama → pastikan
   address yang muncul SAMA seperti sebelumnya (ini membuktikan derivasi
   deterministik bekerja benar)
3. Commit progress ini sebelum lanjut

```bash
git add .
git commit -m "feat: implement wallet generation and import with secure storage"
```

## Status Sebelumnya: Stage 1 — Define (Minggu 1–3)

Yang SUDAH ada di zip ini:
- Struktur folder Clean Architecture (feature-first)
- 4 halaman: Home (list kampanye), Detail Kampanye, Wallet, Upload Bukti
- Routing dengan `go_router` + bottom navigation persisten
- Reusable widgets: `LoadingWidget`, `EmptyStateWidget`, `ErrorStateWidget`, `PrimaryButton`
- Data dummy untuk demo UI (belum terhubung ke blockchain — itu Stage 2)

Yang BELUM ada (sengaja, sesuai tahapan silabus):
- Koneksi ke smart contract (Stage 2)
- Pembuatan/import wallet nyata (Stage 2)
- Kamera, GPS, upload IPFS (Stage 3)

## Cara Menjalankan

1. **Ekstrak zip ini**, lalu buka terminal di folder hasil ekstrak.

2. **Pastikan Flutter SDK sudah terpasang** (cek dengan `flutter doctor`).
   Kalau ada tanda silang merah untuk Android toolchain, beresin dulu
   sebelum lanjut.

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Jalankan di device/emulator:**
   ```bash
   flutter devices        # cek device yang terdeteksi
   flutter run
   ```
   Untuk demo ke dosen, LEBIH BAIK pakai HP Android fisik (kabel USB,
   USB debugging aktif) daripada emulator — sesuai requirement silabus
   "diinstal dan didemonstrasikan pada perangkat nyata".

5. **Inisialisasi Git** (kalau belum):
   ```bash
   git init
   git add .
   git commit -m "chore: scaffold Flutter project with clean architecture structure"
   ```

## Struktur Proyek

Baca `STRUCTURE.md` untuk penjelasan lengkap arsitektur dan alasan di
balik setiap keputusan desain — dokumen ini yang harus kamu pahami
untuk checkpoint dosen.

## Langkah Selanjutnya (Stage 1, sisa Minggu 1-3)

Lihat rencana detail di chat dengan mentor — ringkasannya:
1. Jalankan proyek ini, pastikan semua halaman & navigasi berfungsi
2. Sesuaikan copywriting/warna sesuai selera tim (opsional)
3. Siapkan wireframe/mockup sederhana (Figma/kertas) sebagai bahan
   presentasi Checkpoint Offline 1
4. Commit setiap kali menyelesaikan 1 bagian kecil (jangan menumpuk)
5. Setelah checkpoint 1 lolos, lanjut ke Stage 2 (Wallet + Web3 integration)
