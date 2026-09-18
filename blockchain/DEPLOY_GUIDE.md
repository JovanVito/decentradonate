# Panduan Deploy Smart Contract (100% Gratis)

Lakukan ini SEJAJAR waktu kamu mengetes fitur wallet — supaya di Langkah
2.2 (integrasi web3dart) semua data (RPC URL, contract address, ABI)
sudah siap dan kita tidak perlu jeda menunggu.

## Langkah 1 — Pasang MetaMask & Tambah Jaringan Polygon Amoy

1. Install extension **MetaMask** di browser (Chrome/Firefox/Brave) — gratis.
2. Buat wallet baru DI METAMASK (ini terpisah dari wallet yang dibuat
   aplikasi Flutter kita — MetaMask di sini HANYA dipakai untuk deploy
   contract lewat Remix, bukan dipakai user aplikasi).
3. Tambah jaringan **Polygon Amoy Testnet** ke MetaMask:
   - Buka https://chainlist.org, cari "Polygon Amoy", klik "Add to MetaMask"
   - Atau tambah manual: Network Name: `Polygon Amoy`, RPC URL:
     `https://rpc-amoy.polygon.technology`, Chain ID: `80002`, Symbol: `MATIC`

## Langkah 2 — Ambil Testnet MATIC (Gratis, dari Faucet)

1. Buka https://faucet.polygon.technology
2. Pilih network **Amoy**, tempel address wallet MetaMask kamu
3. Klaim — biasanya dapat 0.5–1 testnet MATIC, cukup untuk puluhan kali
   deploy & testing (gas fee di testnet sangat murah)

## Langkah 3 — Compile & Deploy via Remix (Browser, Gratis, Tanpa Install)

1. Buka https://remix.ethereum.org
2. Buat file baru: `Decentradonate.sol`, copy-paste isi file
   `blockchain/Decentradonate.sol` dari zip proyekmu
3. Tab **Solidity Compiler** (ikon di sidebar kiri):
   - Pilih compiler version `0.8.19` atau lebih baru (masih di rentang `^0.8.19`)
   - Klik **Compile Decentradonate.sol**
4. Tab **Deploy & Run Transactions**:
   - Environment: pilih **"Injected Provider - MetaMask"**
   - Pastikan network di MetaMask sudah Polygon Amoy (cek di pop-up MetaMask)
   - Klik **Deploy**, konfirmasi transaksi di pop-up MetaMask (akan minta
     sedikit testnet MATIC sebagai gas fee)
5. Setelah sukses, di bagian "Deployed Contracts" akan muncul contract
   address (`0x...`) — **COPY alamat ini**.

## Langkah 4 — Ambil ABI

1. Masih di tab **Solidity Compiler**, scroll ke bawah, klik tombol
   **ABI** (ikon copy) — ini akan menyalin JSON ABI ke clipboard.
2. Buka `assets/contracts/donation_abi.json` di proyek Flutter-mu,
   **replace seluruh isi file** dengan ABI yang barusan disalin.

## Langkah 5 — Daftar Alchemy (RPC Provider Gratis)

1. Buat akun gratis di https://www.alchemy.com
2. Create App → pilih chain **Polygon**, network **Amoy**
3. Di dashboard app, copy:
   - **HTTP URL** (format: `https://polygon-amoy.g.alchemy.com/v2/xxxxx`)
   - **WebSocket URL** (format: `wss://polygon-amoy.g.alchemy.com/v2/xxxxx`)

## Langkah 6 — Isi ke Proyek Flutter

Buka `lib/core/constants/contract_constants.dart`, ganti nilai placeholder:

```dart
static const String rpcUrl = 'https://polygon-amoy.g.alchemy.com/v2/API_KEY_KAMU';
static const String wsUrl = 'wss://polygon-amoy.g.alchemy.com/v2/API_KEY_KAMU';
static const String contractAddress = '0xALAMAT_CONTRACT_HASIL_DEPLOY';
```

## Langkah 7 — Buat Campaign Pertama (Wajib untuk Testing Donasi)

Fungsi `donate(campaignId)` di contract akan gagal (`require` di Solidity
menolak) kalau `campaignId` yang dikirim dari app belum ada di contract.
Karena Home screen di app Flutter masih menampilkan data DUMMY (bukan
hasil baca on-chain), kamu harus buat MINIMAL SATU campaign asli secara
manual supaya alur donasi bisa ditest end-to-end:

1. Masih di Remix, tab **Deploy & Run Transactions**, cari contract yang
   sudah ter-deploy di bagian "Deployed Contracts"
2. Expand contract itu, cari fungsi **createCampaign**
3. Isi parameter:
   - `title`: teks bebas, mis. `"Bantu Renovasi Sekolah Darurat di Cianjur"`
     (samakan dengan salah satu judul dummy di `campaign.dart` supaya
     konteksnya nyambung saat demo)
   - `targetAmount`: dalam WEI, bukan MATIC. Untuk target 5 MATIC, isi
     `5000000000000000000` (5 diikuti 18 angka nol)
4. Klik **transact**, konfirmasi di MetaMask
5. Campaign pertama ini otomatis dapat `campaignId = 0` (index array
   dimulai dari 0) — ini SUDAH SELARAS dengan `Campaign(id: '0', ...)`
   pertama di `dummyCampaigns()` pada app Flutter-mu.
6. (Opsional) Ulangi untuk campaign kedua/ketiga kalau mau test lebih
   dari satu, id berikutnya otomatis 1, 2, dst.

## Checklist Sebelum Wallet & Donasi Bisa Ditest Sungguhan

- [ ] Contract berhasil deploy, ada di PolygonScan Amoy
      (cek: https://amoy.polygonscan.com/address/ALAMAT_CONTRACT_KAMU)
- [ ] `donation_abi.json` sudah diganti dengan ABI asli (bukan placeholder)
- [ ] Alchemy API key (HTTP + WSS) sudah didapat
- [ ] `contract_constants.dart` sudah diisi lengkap
- [ ] Minimal satu campaign sudah dibuat lewat `createCampaign` (Langkah 7)
- [ ] Wallet MetaMask kamu (yang deploy) punya testnet MATIC tersisa,
      untuk jaga-jaga kalau perlu redeploy

**Catatan:** kode Flutter untuk baca saldo (Langkah 2.2) dan donasi
(Langkah 2.3) SUDAH SELESAI DITULIS dan siap jalan — tidak menunggu
checklist ini. Begitu semua kotak di atas tercentang dan kredensial
diisi, buka lagi app-nya: saldo & donasi akan langsung berfungsi tanpa
perlu perubahan kode apa pun.
