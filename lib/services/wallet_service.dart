import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/web3dart.dart';

/// Lapisan PALING BAWAH yang menyentuh langsung kriptografi & secure storage.
/// Tidak tahu apa-apa soal Either/Failure (itu urusan repository) — kelas
/// ini murni "tukang kerja": generate, validasi, derive, simpan, baca, hapus.
///
/// KENAPA flutter_secure_storage (bukan SharedPreferences/sqflite)?
/// Karena private key/mnemonic adalah data PALING sensitif di aplikasi ini —
/// siapa pun yang punya mnemonic ini bisa mencuri seluruh dana wallet.
/// flutter_secure_storage menyimpan data terenkripsi lewat Android Keystore
/// (Android) / Keychain (iOS), BUKAN plaintext seperti SharedPreferences.
class WalletService {
  WalletService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  static const _mnemonicKey = 'decentradonate_wallet_mnemonic';

  /// Generate 12 kata baru (128-bit entropy, standar industri untuk wallet
  /// biasa — 24 kata/256-bit dipakai untuk kebutuhan keamanan ekstra tinggi).
  String generateMnemonic() => bip39.generateMnemonic(strength: 128);

  bool isValidMnemonic(String mnemonic) => bip39.validateMnemonic(mnemonic.trim());

  /// Mengubah mnemonic menjadi credentials (private+public key) yang bisa
  /// dipakai web3dart untuk sign transaction.
  ///
  /// CATATAN PENTING: ini simplifikasi, BUKAN derivasi BIP-44 penuh seperti
  /// MetaMask. Kita ambil 32 byte pertama dari seed BIP-39 sebagai private
  /// key secp256k1 secara langsung. Ini tetap kriptografis aman (private key
  /// tetap 256-bit acak berkualitas tinggi dari PBKDF2), TAPI address yang
  /// dihasilkan TIDAK akan sama jika mnemonic yang sama di-import ke
  /// MetaMask/Trust Wallet (mereka pakai path turunan HD wallet BIP-44).
  /// Untuk scope tugas ini itu tidak masalah karena wallet dibuat & dipakai
  /// sepenuhnya di dalam app kita sendiri.
  EthPrivateKey credentialsFromMnemonic(String mnemonic) {
    final seed = bip39.mnemonicToSeed(mnemonic.trim());
    final privateKeyBytes = Uint8List.fromList(seed.sublist(0, 32));
    return EthPrivateKey(privateKeyBytes);
  }

  Future<void> saveMnemonic(String mnemonic) async {
    await _secureStorage.write(key: _mnemonicKey, value: mnemonic.trim());
  }

  Future<String?> readMnemonic() async {
    return _secureStorage.read(key: _mnemonicKey);
  }

  Future<bool> hasWallet() async {
    final value = await _secureStorage.read(key: _mnemonicKey);
    return value != null && value.isNotEmpty;
  }

  Future<void> deleteWallet() async {
    await _secureStorage.delete(key: _mnemonicKey);
  }
}
