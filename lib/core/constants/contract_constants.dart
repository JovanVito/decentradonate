/// Konfigurasi jaringan blockchain & smart contract.
/// SENSAJA dipisah dari kode logic supaya waktu pindah dari local
/// ke testnet/mainnet, cukup ubah file ini saja.
///
/// NILAI DI BAWAH INI SUDAH TERISI (Hardhat Local) — untuk Stage 3.
class ContractConstants {
  ContractConstants._();

  // Hardhat Local Node
  static const int chainId = 31337;
  static const String chainName = 'Hardhat Local';
  static const String nativeCurrencySymbol = 'ETH';

  // Hardhat local RPC
  static const String rpcUrl = 'http://127.0.0.1:8545';
  static const String wsUrl = 'ws://127.0.0.1:8545';

  // Contract address hasil deploy Hardhat (0x5FbDB2315678afecb367f032d93F642f64180aa3)
  static const String contractAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3';

  // Path ke file ABI hasil compile smart contract
  static const String abiAssetPath = 'assets/contracts/donation_abi.json';

  // TODO(Stage 3): isi dengan Pinata JWT API key (free tier, jangan hardcode di git!)
  static const String pinataApiUrl = 'https://api.pinata.cloud/pinning/pinFileToIPFS';

  static const String pinataJwt = 'REPLACE_WITH_PINATA_JWT';

  /// Helper untuk deteksi "masih placeholder atau sudah diisi asli".
  static bool get isRpcConfigured => !rpcUrl.contains('REPLACE_ME');
  static bool get isContractConfigured => !contractAddress.toUpperCase().contains('REPLACE');
  static bool get isPinataConfigured => !pinataJwt.contains('REPLACE');

  /// Helper untuk mendeteksi koneksi ke local node (bukan placeholder).
  static bool get isLocalHost => rpcUrl.contains('127.0.0.1');
}
