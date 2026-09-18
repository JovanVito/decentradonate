# Struktur Proyek — Decentradonate (Stage 1)

Dokumen ini adalah "contekan sah" untuk kamu jelaskan ke dosen. Simpan,
baca ulang sebelum tiap checkpoint.

## Filosofi Arsitektur

Clean Architecture, feature-first, 3 layer:

```
presentation  →  domain  →  data
   (UI)         (aturan)    (implementasi nyata: Web3, sqflite, dll)
```

Aturan besi: **domain tidak boleh import apa pun dari data atau presentation.**
Kenapa? Karena domain berisi aturan bisnis murni ("apa itu Campaign",
"bagaimana progress dihitung") yang harus tetap benar walaupun kamu ganti
RPC provider, database, atau bahkan framework UI. Kalau ditanya dosen
"kenapa dipisah begini, bukan taruh semua di satu file saja?" — jawabannya:
supaya satu perubahan (mis. ganti Alchemy ke provider RPC lain) tidak
merambat ke seluruh codebase.

## Kenapa Belum Pakai Freezed di Stage 1?

`Campaign` di `lib/features/campaign/domain/entities/campaign.dart` adalah
plain Dart class, BUKAN `@freezed`. Ini disengaja: Stage 1 fokus ke
routing & UI, dan proyek harus bisa langsung `flutter run` tanpa
menjalankan `build_runner` dulu. Freezed (dengan file `.freezed.dart` hasil
generate) baru masuk di Stage 2 saat kita butuh serialization JSON (dari
smart contract call) dan Map (untuk cache sqflite).

## Kenapa go_router + StatefulShellRoute?

- **Deep-linking**: link kampanye bisa dibagikan dan langsung membuka
  halaman detail yang benar.
- **StatefulShellRoute.indexedStack**: 3 tab utama (Home/Wallet/Upload
  Proof) punya bottom navigation yang persisten, dan state tiap tab
  (mis. posisi scroll) tidak hilang saat pindah-pindah tab.
- **`extra` parameter**: mengirim object `Campaign` dari Home ke Detail
  tanpa fetch ulang data — penting untuk UX yang terasa cepat meski nanti
  data aslinya datang dari blockchain (yang notabene lambat).

## Kenapa ViewState<T> (bukan langsung bool isLoading)?

Lihat `lib/core/utils/view_state.dart`. Dengan `sealed class` + Dart
pattern matching (`switch` di `home_screen.dart`), compiler MEMAKSA kita
menangani semua kemungkinan state: Initial, Loading, Loaded, Empty, Error.
Ini mencegah bug klasik "lupa handle error state" yang sering jadi alasan
app crash saat demo checkpoint UTS.

## Kenapa Ada Folder `services/` Terpisah dari `features/*/data/`?

`services/` (Stage 2+) berisi singleton tingkat rendah: satu
`Web3Client`, satu instance secure storage. Feature repository (mis.
`CampaignRepositoryImpl`) MEMAKAI service ini, bukan membuat client
baru sendiri-sendiri. Ini mencegah membuka banyak koneksi RPC sekaligus
dan memusatkan penanganan error jaringan di satu tempat.

## Stage 2.1 — Wallet (Generate/Import)

### Alur Data Lengkap

```
UI (WalletScreen)
  ↓ ref.read(walletProvider.notifier).createWallet()
WalletNotifier (AsyncNotifier)
  ↓ ref.read(walletRepositoryProvider).createWallet()
WalletRepositoryImpl                    ← implementasi, tahu detail teknis
  ↓ WalletService.generateMnemonic()    ← bip39
  ↓ WalletService.credentialsFromMnemonic() ← web3dart EthPrivateKey
  ↓ WalletService.saveMnemonic()        ← flutter_secure_storage
  ↑ Either<Failure, WalletInfo>         ← balik ke atas sebagai VALUE, bukan exception
```

Kenapa dipisah 4 lapis untuk sesuatu yang "cuma generate 12 kata"?
Karena tiap lapis punya SATU tanggung jawab yang bisa diuji/diganti
sendiri-sendiri:
- `WalletService` — satu-satunya yang tahu cara kerja bip39/secure storage
- `WalletRepositoryImpl` — menerjemahkan exception jadi Failure yang ramah
- `WalletNotifier` — mengatur state loading/error/data untuk UI
- `WalletScreen` — HANYA menampilkan, tidak tahu apa-apa soal bip39

### Kenapa `AsyncNotifier<WalletInfo?>`, bukan `ViewState` manual seperti Stage 1?

Riverpod `AsyncValue<T>` sudah built-in punya 3 varian (`loading`, `error`,
`data`) yang WAJIB ditangani semua lewat `.when(...)` — jadi kita tidak
perlu bikin ulang `ViewState` untuk data yang bersumber dari provider.
`ViewState` di Stage 1 tetap relevan untuk kasus di mana kita PERLU
membedakan "data kosong" sebagai varian terpisah dari null (mis. nanti
untuk daftar campaign yang panjang). Untuk wallet, `data == null` sudah
cukup jelas artinya "belum ada wallet".

### Kenapa Mnemonic Tidak Disimpan di State Provider Setelah Dibuat?

Lihat `WalletNotifier.createWallet()` — setelah `WalletRepositoryImpl`
mengembalikan `WalletInfo` dengan `mnemonicForBackup` terisi, notifier
SENGAJA menyimpan versi BARU tanpa mnemonic (`WalletInfo(address: ...)`)
ke `state`. Mnemonic-nya sendiri dikembalikan sebagai return value method,
lalu langsung dikirim ke `BackupMnemonicScreen` lewat `extra` dan
TIDAK PERNAH masuk ke provider state lagi. Ini mengurangi "jejak" data
paling sensitif di memory aplikasi seminimal mungkin.

### Simplifikasi yang Harus Kamu Jelaskan ke Dosen

`WalletService.credentialsFromMnemonic()` mengambil 32 byte pertama dari
BIP-39 seed sebagai private key langsung — BUKAN derivasi BIP-44 penuh
(`m/44'/60'/0'/0/0`) seperti MetaMask. Konsekuensinya: mnemonic yang
dihasilkan aplikasi ini TIDAK bisa di-import ke MetaMask untuk address
yang sama. Tetap aman secara kriptografis untuk kebutuhan wallet
mandiri di dalam app kita, tapi sebutkan ini sebagai keterbatasan/area
pengembangan lanjutan saat presentasi.

## Stage 2.2 — Integrasi Web3 (Baca Saldo)

### Kenapa Kode Ini Bisa Ditest SEKARANG, Padahal Contract Belum Di-Deploy?

`getBalance()` HANYA butuh RPC URL (untuk baca saldo native MATIC dari
address manapun) — TIDAK butuh contract address/ABI sama sekali. Tapi
karena kamu belum punya RPC URL Alchemy juga, `ContractConstants.rpcUrl`
masih placeholder. Jalur errornya:

```
WalletScreen buka → walletBalanceProvider jalan
  → WalletRepositoryImpl.getBalance()
  → Web3Service.getBalance()
  → cek ContractConstants.isRpcConfigured → FALSE
  → throw StateError('RPC URL belum dikonfigurasi...')
  ← ditangkap di WalletRepositoryImpl → Left(ConfigurationFailure(...))
  ← walletBalanceProvider re-throw sebagai Exception
  ← UI: balanceAsync.error → _BalanceErrorNote mendeteksi kata
    "belum dikonfigurasi" → tampilkan pesan "Konfigurasi Blockchain
    Belum Lengkap" + arahkan ke DEPLOY_GUIDE.md
```

**Coba jalankan SEKARANG**: buka tab Wallet (dengan wallet yang sudah
ada dari Langkah 2.1) → kamu akan melihat pesan error yang JELAS dan
INFORMATIF, bukan crash atau layar putih. Ini bukti nyata untuk dosen
bahwa error handling sudah dipikirkan dari awal, bukan ditempel belakangan.

### Kenapa `ConfigurationFailure` Dipisah dari `RpcFailure`?

Keduanya sama-sama berujung "saldo gagal dimuat", tapi PENYEBAB dan
SOLUSINYA beda total:
- `ConfigurationFailure` → developer (kamu) yang harus mengisi
  `contract_constants.dart`. User aplikasi (kalau nanti sudah rilis)
  seharusnya TIDAK PERNAH melihat error ini — kalau muncul di versi
  rilis, berarti ada bug proses build.
- `RpcFailure` → masalah runtime sungguhan (internet mati, Alchemy
  down, rate limit habis). Ini yang perlu tombol "Coba Lagi" untuk user.

Membedakan keduanya secara eksplisit dalam kode (bukan cuma pesan teks)
adalah praktik defensive programming yang baik untuk kamu jelaskan saat
viva/checkpoint.

### Kenapa Konversi Wei → MATIC Manual (`wei.toDouble() / 1e18`), Bukan Helper Bawaan?

`EtherAmount.getInWei` (BigInt) adalah API paling stabil lintas versi
web3dart. Helper bawaan lain (mis. `getValueInUnit`) kadang berubah
tanda tangannya antar versi mayor, dan karena `web3dart` versi kita
terkunci ke pubspec yang sudah kamu tetapkan, saya pilih jalur yang
paling minim risiko breaking change. Trade-off: presisi `double` mulai
tidak akurat di angka sangat besar (>15-17 digit signifikan) — tidak
masalah untuk TAMPILAN saldo, tapi kalau nanti ada perhitungan pembagian
dana yang butuh presisi wei penuh, pakai `BigInt` mentah, jangan `double`
hasil konversi ini.

## Stage 2.3 — Fungsi Donasi On-Chain

### Kenapa `walletServiceProvider` Dipindah ke `core/providers/`?

Sebelumnya provider ini didefinisikan di dalam
`features/wallet/presentation/providers/wallet_providers.dart`. Begitu
fitur `donation` juga butuh baca mnemonic (untuk sign transaksi), kalau
tetap di sana, `donation` harus `import` file dari dalam folder internal
`wallet` — melanggar prinsip "tiap fitur berdiri sendiri" yang kita
pegang sejak STRUCTURE.md Stage 1. Solusinya: pindahkan provider untuk
SERVICE lintas-fitur (`WalletService`, `Web3Service`) ke
`core/providers/service_providers.dart`. Sekarang baik `wallet` maupun
`donation` sama-sama mengambil dari sumber netral, bukan dari satu sama
lain.

### Alur Satu Transaksi Donasi, End-to-End

```
DonateBottomSheet (UI)
  ↓ ref.read(donationProvider.notifier).donate(campaignId, amountInMatic)
DonationNotifier (state: idle → loading → data(txHash) | error)
  ↓ ref.read(donationRepositoryProvider).donate(...)
DonationRepositoryImpl
  ↓ WalletService.readMnemonic() + credentialsFromMnemonic()  → EthPrivateKey
  ↓ Web3Service.loadContract()                                 → DeployedContract
  ↓ _maticToWei(amountInMatic)                                 → BigInt wei
  ↓ Web3Client.sendTransaction(credentials, Transaction.callContract(...))
  ↑ String txHash                                               ← dikirim ke blockchain
```

Perhatikan: **tidak ada backend/API custom di alur ini** — Flutter
langsung sign transaksi dengan private key yang ada di HP (via
`flutter_secure_storage`) dan kirim langsung ke node Alchemy. Ini
esensi dari "desentralisasi": tidak ada server perantara yang bisa
menahan atau memanipulasi transaksi donasi.

### Kenapa Konversi MATIC → Wei Lewat String, Bukan `matic * 1e18`?

`double` di Dart (dan hampir semua bahasa pemrograman) memakai floating
point biner, yang TIDAK BISA merepresentasikan banyak pecahan desimal
secara eksak — mis. `0.1` sebenarnya disimpan sebagai
`0.1000000000000000055511151231257827021181583404541015625`. Untuk
angka desimal biasa ini tidak masalah, tapi untuk **nominal uang yang
dikirim sungguhan ke blockchain**, kesalahan pembulatan sekecil apa pun
bisa membuat transaksi mengirim jumlah yang sedikit berbeda dari yang
diketik user. `_maticToWei()` di `DonationRepositoryImpl` mengubah angka
jadi representasi string dulu (`toStringAsFixed(18)`), lalu parse tiap
bagian (utuh & desimal) sebagai `BigInt` — hasilnya presisi penuh, tidak
ada pembulatan floating point sama sekali.

### Kenapa `ref.listen` untuk Dialog Sukses, Bukan `ref.watch`?

`ref.watch` di dalam `build()` akan terpanggil ULANG setiap widget
rebuild selama state provider yang sama. Kalau dipakai untuk memicu
`showDialog`, dialog bisa muncul berkali-kali tiap kali ada rebuild lain
yang tidak terkait (mis. keyboard muncul/hilang) selama state masih
`AsyncData(txHash)` yang sama. `ref.listen` HANYA terpanggil sekali
setiap kali VALUE provider benar-benar berubah — cocok untuk efek
samping satu-kali seperti "tutup sheet lalu tampilkan dialog", bukan
untuk merender UI berulang.

### Keterbatasan yang Harus Kamu Jelaskan Saat Demo

Home screen masih menampilkan **data dummy** (Stage 1), belum baca
daftar campaign asli dari contract. Supaya alur donasi tetap bisa
ditest end-to-end, `id` pada data dummy sengaja diselaraskan (`'0'`,
`'1'`, `'2'`) dengan indexing array `campaigns` di Solidity yang juga
mulai dari 0 — tapi ini TIDAK OTOMATIS sinkron. Kamu tetap harus
membuat campaign sungguhan di contract (`blockchain/DEPLOY_GUIDE.md`
Langkah 7) sebelum tombol "Donasi Sekarang" berhasil on-chain. Sinkronisasi
penuh (Home baca langsung dari contract) adalah pekerjaan lanjutan —
sebutkan ini secara jujur sebagai scope yang disengaja, bukan yang
"belum sempat", saat presentasi checkpoint.

## Checklist Kesiapan Checkpoint Offline 1

- [ ] `flutter run` berhasil tanpa error di HP fisik
- [ ] Navigasi Home → Detail → back berjalan mulus
- [ ] Bottom nav Home/Wallet/Upload Proof berpindah tanpa reset state
- [ ] Bisa tunjukkan ketiga state (Loading/Empty/Error) di Home lewat menu
      titik tiga (⋮) di app bar — ini bukti kamu paham requirement "harus
      ada loading/empty/error state" sejak awal, bukan ditempel belakangan
- [ ] Bisa jelaskan alasan folder domain/data/presentation terpisah
- [ ] Git log menunjukkan commit kecil & bermakna, bukan satu commit raksasa

## Stage 3 — Harden (Proof-of-Impact: Kamera + GPS + IPFS)

### Struktur File Baru

```
proof_of_impact/
├── domain/
│   ├── entities/proof_of_impact.dart          ← entity: id, photoPath, lat, lng, timestamp, ipfsHash
│   └── repositories/proof_of_impact_repository.dart  ← abstract interface
├── data/
│   └── repositories/proof_of_impact_repository_impl.dart  ← IPFS upload via Pinata API
└── presentation/
    ├── providers/proof_of_impact_provider.dart  ← AsyncNotifier (state: idle/loading/success/error)
    └── screens/upload_proof_screen.dart          ← Full: camera preview + GPS + permissions
```

### Alur Data Proof-of-Impact

```
UploadProofScreen (UI)
  → ref.read(proofOfImpactProvider.notifier).uploadProof(photoPath, lat, lng, timestamp)
ProofOfImpactNotifier (AsyncNotifier)
  → state: AsyncLoading → state: AsyncData(ipfsHash) | AsyncError
ProofOfImpactRepositoryImpl
  → http POST ke Pinata API (multipart: foto bytes + metadata JSON)
  → return ipfsHash (String)
```

### Keputusan Desain Kamera

- **CameraPreview live** menggunakan `package:camera` dengan `CameraController`
- **AspectRatio 16:9** hardcoded (stable across devices, menghindari `CameraValue.size` yang bervariasi)
- **Permission handling**: jika user tolak izin → `_cameraError` → tampilkan placeholder dengan pesan jelas + tombol retry
- **Photo capture**: `CameraController.takePicture()` → dapat `XFile` path → simpan di `_capturedImage`
- **Foto tidak dikompresi** sebelum upload (simpel, cukup untuk demo Stage 3)

### Keputusan Desain GPS

- **Geolocator** dengan `LocationSettings` (accuracy: high, timeLimit: 10 detik)
- **Permission handling**: `permission_handler` untuk `Permission.location`
- **Jika ditolak**: `_errorMessage` → Error state dengan pesan "Izin lokasi ditolak"
- **Timeout**: `TimeoutException` dari `dart:async` → pesan "Waktu habis saat mendeteksi lokasi"

### Keputusan Desain IPFS Upload

- **Pinata API**: `POST` ke `https://api.pinata.cloud/pinning/pinFileToIPFS`
- **Multipart request**: file bytes + `pinataMetadata` JSON (lat/lng/timestamp)
- **Authorization**: Bearer JWT dari `ContractConstants.pinataJwt`
- **Error handling**: `SocketException` → network error, HTTP status non-200 → upload failure
- **Pinata JWT tidak dikomit ke git** — placeholder `REPLACE_WITH_PINATA_JWT` di `contract_constants.dart`

### Alur Permission Handling

```
User tap "Ambil Foto" / "Tandai Lokasi"
  → Cek status izin (Permission.camera / Permission.location)
  → Jika denied: request permission
  → Jika permanently denied atau request ditolak:
     → Tampilkan ErrorStateWidget dengan pesan jelas
     → User bisa retry (tap placeholder)
  → Jika granted: jalankan fitur (camera preview / GPS detection)
```

### Daftar File yang Dimodifikasi (Stage 3)

| File | Perubahan |
|------|-----------|
| `contract_constants.dart` | Tambah `pinataJwt`, `isPinataConfigured` |
| `app_strings.dart` | Tambah strings camera/GPS/IPFS |
| `service_providers.dart` | Tambah `proofOfImpactRepositoryProvider` |
| `upload_proof_screen.dart` | Full rewrite dengan camera + GPS + permissions |

### Checklist Kesiapan Checkpoint Offline 3

- [ ] `flutter analyze` tidak ada error
- [ ] Kamera live preview berjalan di HP fisik
- [ ] GPS detection berjalan dengan permission granted
- [ ] Permission denied → Error state jelas (bukan crash)
- [ ] IPFS upload berhasil → IPFS hash ditampilkan
- [ ] Responsive layout (keyboard-safe) di semua layar
- [ ] Uji silang perangkat (peer review)
- [ ] Tidak ada fatal error saat koneksi lambat

## Checklist Kesiapan Checkpoint Offline 1
