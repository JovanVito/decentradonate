/// Entity domain murni untuk wallet.
///
/// `mnemonicForBackup` SENGAJA nullable dan hanya diisi SESAAT setelah
/// `createWallet()` dipanggil — untuk ditampilkan SEKALI di layar backup.
/// Setelah itu, instance `WalletInfo` yang disimpan di state provider
/// TIDAK membawa mnemonic lagi (lihat wallet_providers.dart). Ini mencegah
/// mnemonic "menempel" di memory/state lebih lama dari yang perlu.
class WalletInfo {
  final String address;
  final String? mnemonicForBackup;

  const WalletInfo({required this.address, this.mnemonicForBackup});
}
