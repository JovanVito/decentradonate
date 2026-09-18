import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

import '../core/constants/contract_constants.dart';

/// Singleton yang membungkus SATU instance `Web3Client` untuk seluruh app.
///
/// KENAPA SINGLETON? Kalau tiap layar (Wallet, Home, Detail) bikin
/// `Web3Client` sendiri-sendiri, kita akan buka banyak koneksi HTTP ke
/// Alchemy secara bersamaan tanpa alasan — boros dan bisa kena rate limit
/// di free tier. Dengan satu instance yang dipakai bersama, semua layar
/// berbagi koneksi yang sama.
///
/// KENAPA CEK KONFIGURASI DI SETIAP METHOD, BUKAN LANGSUNG REQUEST?
/// Karena `rpcUrl`/`contractAddress` masih berisi teks placeholder
/// ('REPLACE_ME') sebelum kamu selesai deploy contract. Kalau kita
/// langsung lempar ke `Web3Client`, errornya akan berupa exception jaringan
/// generik yang membingungkan ("Failed host lookup: ...REPLACE_ME").
/// Dengan pengecekan eksplisit, error yang dilempar JELAS bilang APA yang
/// belum kamu isi.
class Web3Service {
  Web3Service._internal();
  static final Web3Service instance = Web3Service._internal();
  factory Web3Service() => instance;

  Web3Client? _client;
  DeployedContract? _contract;

  Web3Client get client {
    _client ??= Web3Client(ContractConstants.rpcUrl, http.Client());
    return _client!;
  }

  /// Baca saldo native token (MATIC) sebuah address.
  /// Return `EtherAmount` (tipe web3dart) — konversi ke `double` yang lebih
  /// ramah-domain dilakukan di `WalletRepositoryImpl`, BUKAN di sini,
  /// supaya layer domain tidak perlu tahu bentuk `EtherAmount` sama sekali.
  Future<EtherAmount> getBalance(String address) async {
    if (!ContractConstants.isRpcConfigured) {
      throw StateError(
        'RPC URL belum dikonfigurasi. Isi `rpcUrl` di contract_constants.dart '
        '(lihat blockchain/DEPLOY_GUIDE.md Langkah 5-6).',
      );
    }
    final ethAddress = EthereumAddress.fromHex(address);
    return client.getBalance(ethAddress);
  }

  /// Load ABI dari assets + bungkus jadi `DeployedContract` siap pakai.
  /// Di-cache di `_contract` supaya file JSON tidak dibaca ulang tiap kali
  /// method donasi/baca-campaign dipanggil (Langkah 2.3).
  Future<DeployedContract> loadContract() async {
    if (_contract != null) return _contract!;

    if (!ContractConstants.isContractConfigured) {
      throw StateError(
        'Contract address belum dikonfigurasi. Isi `contractAddress` di '
        'contract_constants.dart setelah deploy (lihat blockchain/DEPLOY_GUIDE.md).',
      );
    }

    final abiString = await rootBundle.loadString(ContractConstants.abiAssetPath);
    final decoded = jsonDecode(abiString);

    // File placeholder berbentuk objek `{"_comment": "..."}`, BUKAN array
    // ABI asli. Deteksi ini secara eksplisit — daripada `ContractAbi.fromJson`
    // melempar parsing error yang generik dan membingungkan.
    if (decoded is! List) {
      throw StateError(
        'donation_abi.json masih placeholder. Ganti dengan ABI asli hasil '
        'compile contract di Remix (lihat blockchain/DEPLOY_GUIDE.md Langkah 4).',
      );
    }

    final abi = ContractAbi.fromJson(jsonEncode(decoded), 'Decentradonate');
    _contract = DeployedContract(abi, EthereumAddress.fromHex(ContractConstants.contractAddress));
    return _contract!;
  }

  /// Dipanggil saat wallet diganti (import/hapus) atau saat butuh koneksi
  /// baru — mencegah koneksi lama menggantung tanpa guna.
  void dispose() {
    _client?.dispose();
    _client = null;
    _contract = null;
  }
}
