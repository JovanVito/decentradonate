# Mapping Rubrik Flutter → Struktur Decentradonate (Opsi A)

> Dokumen penerjemah 1 halaman untuk dosen penguji.
> Struktur contoh (`screens/`, `routes/`, `models/`) **sudah dipenuhi**, hanya memakai
> penamaan Clean Architecture feature-first. Tidak ada perubahan kode untuk Opsi A.

## 1. Tabel Mapping (syarat → file aktual)

| Syarat Rubrik | Contoh di Soal | File Aktual di Repo | Status |
|---|---|---|---|
| Entry point + root widget | `lib/main.dart`, `lib/app.dart` | `lib/main.dart` (ProviderScope), `lib/app.dart` (MaterialApp.router) | ✅ Persis sama |
| Routing antarhalaman | `routes/app_routes.dart` | `lib/core/router/app_router.dart` + `lib/core/router/app_shell.dart` (go_router `StatefulShellRoute`, bottom nav Home/Wallet/Upload Proof persisten, deep-link `/campaign/:id`) | ✅ Lebih lengkap |
| Prototype Dashboard | `screens/dashboard_screen.dart` | `lib/features/campaign/presentation/screens/home_screen.dart` | ✅ |
| Prototype Detail | `screens/detail_screen.dart` | `lib/features/campaign/presentation/screens/campaign_detail_screen.dart` | ✅ |
| Prototype Login (auth terpusat) | `screens/login_screen.dart` | **Diganti** `lib/features/wallet/presentation/screens/wallet_screen.dart` + `import_wallet_screen.dart` + `backup_mnemonic_screen.dart`. Alasan: tidak ada backend/auth (self-custody, lihat `PROJECT_DEFINITION.md` Out of Scope). Wallet = identitas + login desentralisasi. | ⚠️ Pengganti disengaja, lihat §2 |
| Prototype Profile | `screens/profile_screen.dart` | **Digabung** ke `wallet_screen.dart` (alamat wallet, saldo MATIC, backup mnemonic). Tidak ada file `profile_screen.dart` terpisah. | ⚠️ Pengganti disengaja, lihat §2 |
| Reusable button / input / card / appbar | `widgets/primary_button.dart`, `app_text_field.dart` | `lib/core/widgets/primary_button.dart`, `loading_widget.dart`, `empty_state_widget.dart`, `error_state_widget.dart`, `app_bottom_nav.dart` + `lib/features/campaign/presentation/widgets/campaign_card.dart`, `lib/features/donation/presentation/widgets/donate_bottom_sheet.dart` | ✅ (+ Loading/Empty/Error state) |
| Model data | `models/user_model.dart` | `lib/features/campaign/domain/entities/campaign.dart`, `lib/features/wallet/domain/entities/wallet_info.dart`, `lib/features/proof_of_impact/domain/entities/proof_of_impact.dart`, `lib/features/explorer/domain/entities/transaction_history.dart` (istilah `models/` → `domain/entities/`) | ✅ |
| Service / API | `services/auth_service.dart` | `lib/services/wallet_service.dart` (bip39 + secure storage), `lib/services/web3_service.dart` (RPC), + `lib/features/*/data/repositories/*_impl.dart` (donasi on-chain, IPFS via Pinata). Tidak ada REST API custom — semua data dari blockchain/IPFS. | ✅ |

## 2. Dua Perbedaan yang Harus Dijelaskan Jujur Saat Demo

1. **Tidak ada Login username/password.** Ini scope yang disengaja, bukan lupa.
   Rujukan: `PROJECT_DEFINITION.md` §5 "Tidak ada backend/server custom, tidak ada KYC".
   Demo: tunjukkan Create Wallet → Backup 12 kata → Import Wallet sebagai alur login.
2. **Tidak ada `profile_screen.dart`.** Fungsinya ada di tab Wallet.
   Demo: buka tab Wallet → tunjukkan address + saldo + tombol backup.

## 3. Urutan Demo 3 Menit (bukti semua konsep)

1. `flutter run` di HP fisik → tab Home (Dashboard) → scroll campaign dummy.
2. Tap card → Detail (`extra` Campaign tanpa refetch) → tap Donasi → `DonateBottomSheet`.
3. Bottom nav Home/Wallet/Upload Proof → state tiap tab tidak reset (bukti `StatefulShellRoute`).
4. Menu ⋮ di app bar Home → tunjukkan Loading / Empty / Error state (syarat "harus ada loading/empty/error").
5. Tab Wallet → buat wallet → tunjukkan `BackupMnemonicScreen` (mnemonic tidak disimpan di provider state, hanya di-return sekali — lihat `STRUCTURE.md` Stage 2.1).

## 4. Cheat-Sheet Jawaban Viva (1 menit per pertanyaan)

- **"Kenapa tidak taruh semua di satu file / folder screens saja?"**
  → Supaya 1 perubahan (ganti Alchemy → RPC lain) tidak merambat ke UI.
  Aturan besi: `domain` tidak boleh import `data`/`presentation` (`STRUCTURE.md:15`, `Architecture.md` Filosofi).
- **"Kenapa go_router + StatefulShellRoute, bukan Navigator.push?"**
  → Deep-linking (`/campaign/:id` bisa di-share) + bottom nav persisten tanpa reset scroll (`STRUCTURE.md:32-41`).
- **"Kenapa ViewState sealed class, bukan bool isLoading?"**
  → Compiler memaksa handle Initial/Loading/Loaded/Empty/Error, cegah lupa handle error saat demo (`lib/core/utils/view_state.dart`).
- **"Kenapa mnemonic tidak disimpan di state?"**
  → Dikembalikan sekali via return value → dikirim ke Backup screen via `extra`, tidak masuk provider state (minimalkan jejak rahasia di memori).
- **"Kenapa Home masih dummy?"**
  → Scope disengaja Stage 1 fokus routing+UI; sinkronisasi on-chain penuh pekerjaan lanjutan. ID dummy `'0','1','2'` diselaraskan dengan index array Solidity untuk test donasi end-to-end (`STRUCTURE.md:228-239`).

## 5. Referensi Silang Dokumen

- Arsitektur penuh: `Architecture.md`, `STRUCTURE.md`
- Scope & kriteria lulus: `PROJECT_DEFINITION.md` §4–§6
- Konstanta chain/RPC/IPFS: `lib/core/constants/contract_constants.dart`
