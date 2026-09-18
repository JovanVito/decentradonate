# Architecture — Decentradonate

Aplikasi donasi mikro terdesentralisasi berbasis **Flutter + Polygon Amoy Testnet** dengan **Proof-of-Impact** (Kamera, GPS, IPFS).

---

## Overview

**Decentradonate** adalah aplikasi mobile yang memungkinkan donatur memberikan donasi mikro langsung ke organizer kampanye melalui smart contract di blockchain Polygon Amoy Testnet. Setiap donasi tercatat secara transparan dan tidak dapat diubah di blockchain. Organizer wajib mengunggah Proof-of-Impact (foto + lokasi GPS) ke IPFS sebagai bukti penggunaan dana.

**Tujuan:** Menyelesaikan proyek 12 minggu (12 pertemuan) berdasarkan silabus Mobile Programming dengan 4 checkpoint offline.

---

## Teknologi yang Digunakan

| Layer | Teknologi |
|---|---|
| **Framework UI** | Flutter (Dart) |
| **State Management** | Riverpod 2.x (`AsyncNotifier`, `Provider`, `ConsumerWidget`) |
| **Routing** | go_router 14.x (`StatefulShellRoute`, `IndexedStack`) |
| **Blockchain** | web3dart 2.x (Polygon Amoy Testnet RPC via Alchemy) |
| **Smart Contract** | Solidity ^0.8.19 (Hardhat) |
| **Local Storage** | sqflite + `flutter_secure_storage` (encrypted mnemonic) |
| **Wallet** | bip39 (mnemonic 12 kata), web3dart `EthPrivateKey` |
| **IPFS** | Pinata API (upload proof-of-impact) |
| **Kamera** | `package:camera` |
| **GPS** | `package:geolocator` |
| **Permissions** | `package:permission_handler` |
| **Network Detection** | `connectivity_plus` |
| **Code Generation** | `freezed`, `json_serializable`, `riverpod_generator` (Stage 2+) |
| **Error Handling** | `dartz` (`Either<Failure, T>`) |

---

## Filosofi Arsitektur

**Clean Architecture, feature-first, 3 layer:**

```
presentation  →  domain  →  data
   (UI)        (aturan)    (implementasi nyata: Web3, sqflite, IPFS, dll)
```

**Aturan besi:** `domain` **tidak boleh import** apa pun dari `data` atau `presentation`.

**Alasan:** `domain` berisi aturan bisnis murni ("apa itu Campaign", "bagaimana progress dihitung") yang harus tetap benar walaupun kamu ganti RPC provider, database, atau bahkan framework UI. Kalau ditanya dosen "kenapa dipisah begini, bukan taruh semua di satu file saja?" — jawabannya: supaya satu perubahan (mis. ganti Alchemy ke provider RPC lain) tidak merambat ke seluruh codebase.

---

## Struktur Proyek

```
lib/
├── main.dart                          // Entry point — ProviderScope
├── app.dart                           // DecentradonateApp — MaterialApp.router
├── core/
│   ├── constants/
│   │   ├── contract_constants.dart    // Chain ID, RPC URL, contract address, ABI path, Pinata JWT
│   │   ├── app_strings.dart           // Semua teks statis (Indonesia)
│   │   └── app_colors.dart            // Warna tema aplikasi
│   ├── errors/
│   │   ├── failures.dart              // Failure classes (Network, Rpc, Configuration, Transaction, Cache, Wallet, Permission, Ipfs, Unexpected)
│   │   └── exceptions.dart            // ServerException, CacheException, RpcException (layer data only)
│   ├── providers/
│   │   └── service_providers.dart     // Lintas-fitur providers (WalletService, Web3Service, ProofOfImpactRepository)
│   ├── router/
│   │   ├── app_router.dart            // GoRouter — semua rute aplikasi
│   │   └── app_shell.dart             // Bottom navigation shell (Home/Wallet/Upload Proof)
│   ├── theme/
│   │   └── app_theme.dart             // Light/Dark theme config
│   ├── utils/
│   │   └── view_state.dart            // ViewState<T> sealed class (Initial/Loading/Loaded/Empty/Error)
│   └── widgets/
│       ├── primary_button.dart
│       ├── loading_widget.dart
│       ├── error_state_widget.dart
│       └── empty_state_widget.dart
├── features/                          // Feature-first folder
│   ├── campaign/
│   │   ├── domain/
│   │   │   ├── entities/campaign.dart // Campaign entity (plain Dart class)
│   │   │   └── repositories/campaign_repository.dart // Abstract interface
│   │   ├── data/
│   │   │   └── repositories/          // CampaignRepositoryImpl (on-chain read)
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── home_screen.dart
│   │       │   └── campaign_detail_screen.dart
│   │       └── widgets/
│   │           └── campaign_card.dart
│   ├── wallet/
│   │   ├── domain/
│   │   │   ├── entities/wallet_info.dart
│   │   │   └── repositories/wallet_repository.dart
│   │   ├── data/
│   │   │   └── repositories/wallet_repository_impl.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── wallet_screen.dart
│   │   │   │   ├── backup_mnemonic_screen.dart
│   │   │   │   └── import_wallet_screen.dart
│   │   │   └── providers/wallet_providers.dart
│   │   └── domain/repositories/
│   ├── donation/
│   │   ├── domain/
│   │   │   └── repositories/donation_repository.dart
│   │   ├── data/
│   │   │   └── repositories/donation_repository_impl.dart
│   │   └── presentation/
│   │       ├── widgets/donate_bottom_sheet.dart
│   │       └── providers/donation_providers.dart
│   └── proof_of_impact/
│       ├── domain/
│       │   ├── entities/proof_of_impact.dart
│       │   └── repositories/proof_of_impact_repository.dart
│       ├── data/
│       │   └── repositories/proof_of_impact_repository_impl.dart
│       └── presentation/
│           ├── screens/upload_proof_screen.dart
│           └── providers/proof_of_impact_provider.dart
└── services/                          // Singleton low-level services
    ├── web3_service.dart              // Web3Client koneksi ke Alchemy RPC
    └── wallet_service.dart            // generateMnemonic, credentialsFromMnemonic, saveMnemonic
```

---

## Entity & Domain Model

### Campaign

```dart
class Campaign {
  final String id;              // On-chain campaign ID (uint256 -> string)
  final String title;
  final String description;
  final String organizer;       // Wallet address
  final double targetAmount;    // dalam MATIC
  final double collectedAmount; // dalam MATIC
  final String? imageUrl;

  double get progressPercent =>
      targetAmount <= 0 ? 0 : (collectedAmount / targetAmount).clamp(0, 1);
}
```

**Sumber data:** On-chain (smart contract `getCampaign()`), diganti dari dummy data di Stage 2.

### WalletInfo

```dart
class WalletInfo {
  final String address;
  final String? mnemonicForBackup; // Hanya ada di return value saat createWallet
}
```

**Penyimpanan:** Mnemonic dienkripsi via `flutter_secure_storage`. Mnemonic **tidak pernah** disimpan di Riverpod state setelah pembuatan.

### ProofOfImpact

```dart
class ProofOfImpact {
  final String id;
  final String photoPath;
  final double lat;
  final double lng;
  final int timestamp;
  final String ipfsHash;
}
```

**Sumber data:** Kamera HP + GPS → upload ke IPFS via Pinata API → dapat IPFS hash.

---

## State Management

**Riverpod 2.x** dengan pola berikut:

| Pola | Digunakan Untuk | Contoh |
|---|---|---|
| `AsyncNotifier<T>` | Data async (wallet, donation, proof) | `WalletNotifier`, `DonationNotifier`, `ProofOfImpactNotifier` |
| `Provider<T>` | Singleton service | `walletServiceProvider`, `web3ServiceProvider` |
| `ref.watch` / `ref.listen` | State consumer di UI | `ref.listen` untuk dialog sukses satu-kali |

**ViewState<T>** (Stage 1): `sealed class` dengan `ViewInitial`, `ViewLoading`, `ViewLoaded`, `ViewEmpty`, `ViewError`. Compiler MEMAKSA handling semua state — mencegah bug "lupa handle error state".

**AsyncValue<T>** (Stage 2+): `riverpod` built-in `loading`/`error`/`data` via `.when(...)`.

---

## Routing

**go_router** dengan `StatefulShellRoute.indexedStack`:

```
/                    → HomeScreen (tab 0)
  /campaign/:id      → CampaignDetailScreen
/wallet              → WalletScreen (tab 1)
  /wallet/backup     → BackupMnemonicScreen
  /wallet/import     → ImportWalletScreen
/upload-proof        → UploadProofScreen (tab 2)
```

**Kenapa `StatefulShellRoute`?**
- **Bottom navigation persisten** — state tiap tab tidak hilang saat pindah tab
- **Deep-linking** — link kampanye bisa dibagikan dan langsung buka halaman detail
- **`extra` parameter** — kirim object `Campaign` antar halaman tanpa refetch

---

## Data Flow — Wallet (Stage 2.1)

```
UI (WalletScreen)
  ↓ ref.read(walletProvider.notifier).createWallet()
WalletNotifier (AsyncNotifier)
  ↓ ref.read(walletRepositoryProvider).createWallet()
WalletRepositoryImpl
  ↓ WalletService.generateMnemonic()      ← bip39
  ↓ WalletService.credentialsFromMnemonic() ← web3dart EthPrivateKey
  ↓ WalletService.saveMnemonic()          ← flutter_secure_storage
  ↑ Either<Failure, WalletInfo>            ← balik ke atas sebagai VALUE
```

**4 lapis, 1 tanggung jawab tiap lapis:**
1. `WalletService` — bip39/secure storage
2. `WalletRepositoryImpl` — exception → Failure
3. `WalletNotifier` — state loading/error/data
4. `WalletScreen` — HANYA menampilkan

---

## Data Flow — Donasi On-Chain (Stage 2.3)

```
DonateBottomSheet (UI)
  ↓ ref.read(donationProvider.notifier).donate(campaignId, amountInMatic)
DonationNotifier (idle → loading → data(txHash) | error)
  ↓ ref.read(donationRepositoryProvider).donate(...)
DonationRepositoryImpl
  ↓ WalletService.readMnemonic() + credentialsFromMnemonic() → EthPrivateKey
  ↓ Web3Service.loadContract()                                  → DeployedContract
  ↓ _maticToWei(amountInMatic)                                  → BigInt wei
  ↓ Web3Client.sendTransaction(credentials, Transaction.callContract(...))
  ↑ String txHash                                                  ← dikirim ke blockchain
```

**Konversi MATIC → Wei Lewat String:** `_maticToWei()` mengubah angka jadi representasi string dulu (`toStringAsFixed(18)`), lalu parse tiap bagian sebagai `BigInt` — presisi penuh, tidak ada pembulatan floating point.

---

## Blockchain Integration

**Smart Contract** (`blockchain/Decentradonate.sol`):
- Solidity ^0.8.19
- Fungsi utama: `createCampaign()`, `donate()`, `getCampaign()`, `getCampaignCount()`
- Event: `CampaignCreated`, `DonationReceived`
- **Donasi langsung ke organizer wallet** (bukan ditahan di kontrak) — atomic via `.transfer()`
- Deploy ke **Polygon Amoy Testnet** via Hardhat

**Web3 Service** (`services/web3_service.dart`):
- Singleton `Web3Client` koneksi ke Alchemy RPC
- `loadContract()` → `DeployedContract` dari ABI + address
- `sendTransaction()` → kirim transaksi on-chain

**Configuration** (`core/constants/contract_constants.dart`):
- `rpcUrl`, `contractAddress`, `abiAssetPath`
- Helper: `isRpcConfigured`, `isContractConfigured` — deteksi placeholder
- Jika belum terconfigurasi → tampilkan pesan "Konfigurasi Blockchain Belum Lengkap" (bukan crash)

---

## Error Handling

**Pola:** `Either<Failure, T>` dari package `dartz`.

**Alur:** `Datasource throws Exception` → `Repository catches` → `returns Left(Failure)` → `UI handles via state`.

| Failure Class | Kapan Terjadi |
|---|---|
| `NetworkFailure` | Tidak ada koneksi internet |
| `RpcFailure` | RPC node (Alchemy) tidak bisa dihubungi/timeout |
| `ConfigurationFailure` | RPC URL/contract address/ABI belum diisi |
| `TransactionFailure` | Transaksi ditolak smart contract (saldo tidak cukup) |
| `CacheFailure` | Kegagalan baca/tulis sqflite |
| `WalletFailure` | Mnemonic tidak valid, gagal derive private key |
| `PermissionFailure` | Izin Camera/GPS ditolak user |
| `IpfsFailure` | Upload ke IPFS (Pinata) gagal |
| `UnexpectedFailure` | Fallback untuk error tak terduga |

---

## IPFS & Proof-of-Impact (Stage 3)

**Alur:**
```
UploadProofScreen (UI)
  → CameraController.takePicture() → XFile path
  → Geolocator.getLocation() → lat, lng
  → ProofOfImpactNotifier.uploadProof(photoPath, lat, lng, timestamp)
  → ProofOfImpactRepositoryImpl
  → http POST ke Pinata API (multipart: foto bytes + metadata JSON)
  → return ipfsHash (String)
```

**Penyimpanan:** Pinata API (`https://api.pinata.cloud/pinning/pinFileToIPFS`), JWT tidak dikomit ke git.

---

## Konvensi Penamaan

| Item | Konvensi |
|---|---|
| Class / Interface / Enum | **PascalCase** |
| Local variable | **camelCase** |
| File | **snake_case** |
| Folder | **snake_case** |
| Constant | **camelCase** (static final/const) |
| Provider | nama_domain + `Provider`/`Notifier` suffix |

---

## Tahapan Pengembangan (12 Minggu / 12 Pertemuan)

### Stage 1 — Define (Minggu 1–3)
- Struktur folder Clean Architecture (feature-first)
- 4 halaman utama: Home, Detail Kampanye, Wallet, Upload Bukti
- Routing `go_router` + bottom navigation persisten
- Reusable widgets: `LoadingWidget`, `EmptyStateWidget`, `ErrorStateWidget`, `PrimaryButton`
- Data dummy untuk demo UI
- `ViewState<T>` sealed class

### Stage 2 — Build Core Experience (Minggu 4–7)
- **2.1 Wallet**: Generate/import wallet, mnemonic terenkripsi
- **2.2 Integrasi Web3**: Baca saldo MATIC via Alchemy RPC
- **2.3 Donasi On-Chain**: Transfer MATIC ke smart contract, status transaksi

### Stage 3 — Harden (Minggu 8–10)
- **Proof-of-Impact**: Kamera + GPS + IPFS upload
- Permission handling lengkap
- Error handling jaringan lambat/terputus
- Sinkronisasi daftar campaign dari on-chain data

### Stage 4 — Release (Minggu 11–12)
- APK rilis untuk perangkat Android fisik
- Final testing & documentation
- Checkpoint offline final

---

## Keterbatasan Teknis (Harus Dijelaskan Saat Demo)

1. **Tidak ada derivasi BIP-44 penuh.** `WalletService.credentialsFromMnemonic()` mengambil 32 byte pertama dari BIP-39 seed sebagai private key langsung — BUKAN `m/44'/60'/0'/0/0` seperti MetaMask. Mnemonic yang dihasilkan **tidak bisa di-import ke MetaMask** untuk address yang sama. Aman secara kriptografis untuk wallet mandiri, tapi ini keterbatasan yang harus disebutkan secara jujur.

2. **Home screen menampilkan data dummy** (Stage 1), belum baca daftar campaign asli dari contract. Sinkronisasi penuh (Home baca langsung dari contract) adalah pekerjaan lanjutan — sebutkan sebagai scope yang disengaja, bukan "belum sempat".

3. **Tidak ada iOS support.** Pengembangan dan pengujian difokuskan penuh pada Android sesuai konteks tugas.

---

## Dependencies Utama (pubspec.yaml)

```yaml
dependencies:
  flutter_riverpod: ^2.5.1       # State management
  go_router: ^14.2.0             # Routing
  web3dart: ^2.7.3               # Blockchain interaction
  http: ^1.2.2                   # HTTP client
  flutter_secure_storage: ^9.2.2 # Encrypted mnemonic storage
  bip39: ^1.0.6                  # Mnemonic generation
  sqflite: ^2.3.3                # Local database (Stage 2+)
  camera: ^0.11.0+2              # Camera (Stage 3)
  geolocator: ^13.0.1            # GPS (Stage 3)
  permission_handler: ^11.3.1    # Permissions (Stage 3)
  connectivity_plus: ^6.0.5      # Network detection
  dartz: ^0.10.1                 # Either<Failure, T>
  freezed_annotation: ^2.4.1     # Code gen (Stage 2+)
  json_annotation: ^4.9.0        # Code gen (Stage 2+)

dev_dependencies:
  build_runner: ^2.4.12          # Code generation
  freezed: ^2.5.7                # Immutable models
  json_serializable: ^6.8.0      # JSON serialization
  riverpod_generator: ^2.4.3     # Riverpod code gen
```

---

## Catatan Penting

- **Tidak ada backend/server custom.** Seluruh data bersumber dari blockchain (on-chain) dan IPFS.
- **Tidak ada autentikasi.** Asumsi satu lecturer/dosen menggunakan aplikasi (sesuai konteks tugas akhir).
- **Aplikasi berjalan di Polygon Amoy Testnet** — bukan mainnet/produksi. Tidak ada transaksi dana sungguhan.
- **Semua error harus ditampilkan secara informatif** — tidak boleh ada crash/fatal error saat kondisi jaringan lambat atau konfigurasi belum lengkap.
- **Commit Git harus menunjukkan progres bertahap** yang bermakna (bukan satu commit besar di akhir).
