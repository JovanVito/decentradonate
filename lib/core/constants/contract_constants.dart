/// Konfigurasi jaringan blockchain & smart contract.
/// SENGAJA dipisah dari kode logic supaya waktu pindah dari Testnet
/// ke Mainnet (kalau nanti diperlukan), cukup ubah file ini saja.
///
/// NILAI DI BAWAH INI MASIH PLACEHOLDER — akan diisi nyata di Stage 2
/// saat smart contract sudah di-deploy ke Polygon Amoy Testnet.
class ContractConstants {
  ContractConstants._();

  // Polygon Amoy Testnet
  static const int chainId = 80002;
  static const String chainName = 'Polygon Amoy Testnet';
  static const String nativeCurrencySymbol = 'MATIC';

  // TODO(Stage 2): ganti dengan Alchemy HTTP RPC URL asli (free tier)
  static const String rpcUrl = 'https://polygon-amoy.g.alchemy.com/v2/REPLACE_ME';

  // TODO(Stage 2): ganti dengan WebSocket URL Alchemy (untuk listen event realtime)
  static const String wsUrl = 'wss://polygon-amoy.g.alchemy.com/v2/REPLACE_ME';

  // TODO(Stage 2): isi setelah smart contract di-deploy (mis. via Remix/Hardhat)
  static const String contractAddress = '0xREPLACE_WITH_DEPLOYED_ADDRESS';

  // Path ke file ABI hasil compile smart contract
  static const String abiAssetPath = 'assets/contracts/donation_abi.json';

  // TODO(Stage 3): isi dengan Pinata JWT API key (free tier, jangan hardcode di git!)
  static const String pinataApiUrl = 'https://api.pinata.cloud/pinning/pinFileToIPFS';

  // TODO(Stage 3): isi dengan Pinata JWT API key
  static const String pinataJwt = 'REPLACE_WITH_PINATA_JWT';

  /// Helper untuk deteksi "masih placeholder atau sudah diisi asli".
  /// Dipakai Web3Service/WalletRepositoryImpl supaya kegagalan konfigurasi
  /// terdeteksi SEBELUM mencoba request jaringan yang pasti gagal —
  /// menghasilkan pesan error yang jelas ("belum dikonfigurasi") alih-alih
  /// error jaringan yang membingungkan (mis. "Failed host lookup").
  static bool get isRpcConfigured => !rpcUrl.contains('REPLACE_ME');

  static bool get isContractConfigured => !contractAddress.toUpperCase().contains('REPLACE');

  static bool get isPinataConfigured => !pinataJwt.contains('REPLACE');
}
