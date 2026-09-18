import 'package:flutter/material.dart';

/// Palet warna terpusat.
/// Kenapa harus terpusat? Supaya kalau lecturer/tim minta ganti tema,
/// kita ubah di satu tempat, bukan cari-cari hex code di 20 file berbeda.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6C4FD6); // ungu, kesan trust + web3
  static const Color secondary = Color(0xFF00C896); // hijau, kesan "impact/hasil"
  static const Color background = Color(0xFFF7F7FB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6E6E82);
  static const Color error = Color(0xFFE5484D);
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF5A623);
}
