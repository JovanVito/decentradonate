# Panduan Konfigurasi Eksternal — Sepenuhnya Gratis

Ikuti langkah berikut secara berurutan. Semua langkah menggunakan alat gratis dan browser.

## Langkah 1 — Install MetaMask

1. Buka [https://metamask.io](https://metamask.io)
2. Install ekstensi browser untuk Chrome/Firefox/Brave
3. Buat **wallet baru** — catat 12 kata seed phrase secara manual di kertas (JANGAN screenshot, JANGAN simpan di cloud)
4. Buat password yang kuat
5. **Verifikasi**: Buka MetaMask → pastikan ada alamat `0x...` dan "Network: Ethereum Mainnet"

## Langkah 2 — Tambah Jaringan Polygon Amoy ke MetaMask

1. Buka [https://chainlist.org](https://chainlist.org)
2. Cari **"Polygon Amoy"**
3. Klik **"Add to MetaMask"** → konfirmasi di pop-up MetaMask
4. **Verifikasi**: Buka MetaMask → di dropdown network → pastikan "Polygon Amoy" muncul dengan Chain ID `80002`

**Jika chainlist.org tidak berfungsi**, tambah manual di MetaMask:
- Network Name: `Polygon Amoy`
- New RPC URL: `https://rpc-amoy.polygon.technology`
- Chain ID: `80002`
- Currency Symbol: `MATIC`
- Block Explorer URL: `https://amoy.polygonscan.com`

## Langkah 3 — Dapat Testnet MATIC (Gratis)

1. Buka [https://faucet.polygon.technology](https://faucet.polygon.technology)
2. Pastikan network dipilih **Amoy**
3. Paste **MetaMask address** kamu (copy dari MetaMask)
4. Klik **Claim**
5. Tunggu beberapa detik → MATIC muncul di wallet MetaMask (biasanya 0.5–1 MATIC)
6. **Verifikasi**: Buka MetaMask → lihat saldo MATIC

## Langkah 4 — Daftar Alchemy (RPC Provider Gratis)

1. Buka [https://alchemy.com](https://alchemy.com)
2. Klik **Sign Up** → daftar dengan email
3. Klik **"Create App"**
4. Isi:
   - App Name: `Decentradonate`
   - App Description: `Tugas akhir mobile programming`
   - App URL: `http://localhost`
   - **Chain**: `Polygon`
   - **Network**: `Amoy`
5. Klik **Create App**
6. Di dashboard aplikasi kamu, cari:
   - **HTTPS URL** → format: `https://polygon-amoy.g.alchemy.com/v2/YOUR_KEY`
   - **WSS URL** → format: `wss://polygon-amoy.g.alchemy.com/v2/YOUR_KEY`
7. **Salin kedua URL** ini — kamu butuhnya di Langkah 6
8. **Verifikasi**: Pastikan URL mengandung `polygon-amoy.g.alchemy.com/v2/` dan bukan `REPLACE_ME`

## Langkah 5 — Deploy Smart Contract via Remix

1. Buka [https://remix.ethereum.org](https://remix.ethereum.org)
2. Di sidebar kiri, klik **"+"** (New File) → beri nama `Decentradonate.sol`
3. Paste seluruh isi file `blockchain/Decentradonate.sol` dari proyek kamu ke sini
4. Di sidebar kiri, buka tab **Solidity Compiler** (ikon ikon)
   - Compiler Version: pilih **`0.8.19`** (atau yang paling mendekati)
   - Klik **"Compile Decentradonate.sol"**
   - Tunggu sampai tidak ada error
5. Buka tab **Deploy & Run Transactions** (ikon playing)
6. Di dropdown **ENVIRONMENT**: pilih **"Injected Provider - MetaMask"**
7. Pastikan MetaMask sudah terhubung ke **Polygon Amoy** (cek di pop-up MetaMask)
8. Klik **"Deploy"**
9. Konfirmasi transaksi di pop-up MetaMask (bayar gas fee dengan testnet MATIC)
10. Tunggu transaksi konfirmasi (~30 detik)
11. **Verifikasi**: Di bagian "Deployed Contracts" akan muncul contract kamu dengan alamat `0x...`
12. **Salin alamat kontrak ini** — kamu butuh di Langkah 7

## Langkah 6 — Ambil ABI (Application Binary Interface)

1. Masih di Remix, buka tab **Solidity Compiler**
2. Scroll ke **bawah** → klik tombol **ABI** (ikon copy)
3. Buka file `assets/contracts/donation_abi.json` di proyek Flutter-mu
4. **Replace seluruh isi file** dengan ABI yang baru saja kamu salin
5. **Verifikasi**: File harus berisi array JSON besar dengan objek `type: "function"`, `type: "event"`, dll. JANGAN ada `_comment` placeholder lagi.

## Langkah 7 — Buat Campaign Pertama (Wajib untuk Testing Donasi)

Fungsi `donate(campaignId)` akan gagal kalau campaign yang kamu kirim dari app belum ada di contract. Karena Home screen masih menampilkan data dummy, kamu perlu buat campaign manual agar campaignId = 0 ada di contract.

1. Di Remix → tab **Deploy & Run Transactions**
2. Di bagian "Deployed Contracts" → cari contract `Decentradonate` kamu
3. Klik **">>"** (expand)
4. Cari fungsi **`createCampaign`**
5. Isi parameter:
   - `title`: `"Bantu Renovasi Sekolah Darurat di Cianjur"` (sama dengan dummy campaign pertama)
   - `targetAmount`: `5000000000000000000` (= 5 MATIC dalam wei)
6. Klik **"transact"** → konfirmasi di MetaMask
7. **Verifikasi**: Di Remix → "Transaction" → pastikan status **Success**
8. Campaign pertama ini otomatis dapat `campaignId = 0` (array indexing dimulai dari 0)
9. (Opsional) Ulangi untuk campaign lain dengan targetAmount berbeda

## Langkah 8 — Isi `contract_constants.dart`

Buka `lib/core/constants/contract_constants.dart` dan ganti:

```dart
// SEBELUM (placeholder):
static const String rpcUrl = 'https://polygon-amoy.g.alchemy.com/v2/REPLACE_ME';
static const String wsUrl = 'wss://polygon-amoy.g.alchemy.com/v2/REPLACE_ME';
static const String contractAddress = '0xREPLACE_WITH_DEPLOYED_ADDRESS';

// SESUDAH (isi dari Langkah 4 & 5):
static const String rpcUrl = 'https://polygon-amoy.g.alchemy.com/v2/YOUR_ALCHEMY_KEY';
static const String wsUrl = 'wss://polygon-amoy.g.alchemy.com/v2/YOUR_ALCHEMY_KEY';
static const String contractAddress = '0xALAMAT_KONTRAK_HASIL_DEPLOY';
```

**Jangan lupa** tambah Pinata JWT (untuk Fase 3/IPFS):
```dart
static const String pinataApiUrl = 'https://api.pinata.cloud/pinning/pinFileToIPFS';
// Pinata JWT didapat di Langkah 9
```

## Langkah 9 — Daftar Pinata (untuk IPFS Upload — Fase 3)

1. Buka [https://pinata.cloud](https://pinata.cloud)
2. Klik **"Get Started"** → daftar dengan email
3. Klik **"JWT API Keys"** di sidebar kiri → **"Create New Key"**
4. Beri nama: `Decentradonate-dev` → centang **"Admin"** → klik **Create**
5. **Salin JWT** yang muncul (SIMPAN DI AMAN — hanya tampil sekali)
6. Isi di `contract_constants.dart`:
   ```dart
   // Tambahkan field di ContractConstants:
   static const String pinataJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
   ```

## Langkah 10 — Verifikasi Semua Konfigurasi

1. Buka proyek Flutter, jalankan `flutter pub get`
2. Jalankan app: `flutter run`
3. Buka tab **Wallet** → buat atau import wallet
4. Lihat saldo → **harus menampilkan angka MATIC** (bukan pesan "Konfigurasi Belum Lengkap")
5. Buka tab **Campaign Detail** → coba donasi 0.01 MATIC ke campaignId 0
6. Cek di [https://amoy.polygonscan.com](https://amoy.polygonscan.com) → paste wallet address → lihat transaksi donasi

## Checklist

- [ ] MetaMask terinstall dan sudah beralih ke Polygon Amoy
- [ ] Testnet MATIC diterima dari faucet
- [ ] Akun Alchemy aktif dengan App Polygon Amoy
- [ ] Contract berhasil deploy di Remix → alamat `0x...`
- [ ] `donation_abi.json` berisi ABI asli (bukan placeholder)
- [ ] `contract_constants.dart` terisi: `rpcUrl`, `wsUrl`, `contractAddress`
- [ ] Minimal 1 campaign dibuat via `createCampaign` di Remix (campaignId = 0)
- [ ] Akun Pinata aktif dengan JWT key
- [ ] `contract_constants.dart` terisi `pinataJwt`
- [ ] App menampilkan saldo MATIC wallet (bukan ConfigurationFailure)
- [ ] Donasi berhasil → transaction muncul di PolygonScan Amoy

## Catatan Penting

- **API key dan JWT TIDAK BOLEH di-commit ke git.** Jika sudah commit, segera rotate key di dashboard Alchemy/Pinata dan hapus dari git history.
- **Jangan share seed phrase** wallet MetaMask atau seed phrase wallet aplikasi Flutter ke siapa pun.
- **Testnet MATIC bisa diisi ulang** jika habis — tidak ada batasan pengisian dari faucet.
- **Jika contract perlu di-deploy ulang**, alamat akan berubah — update `contract_constants.dart` dan buat ulang campaign di Remix.
