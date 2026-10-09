import 'package:flutter/material.dart';

/// Palet warna terpusat mengikuti konsep desain "Riak".
/// Donasi kecil = batu dijatuhkan ke air; efeknya menyebar.
class AppColors {
  AppColors._();

  /// Tinta Hutan — warna utama, dipakai untuk teks dan permukaan gelap.
  static const Color ink = Color(0xFF16231D);
  static const Color inkSoft = Color(0xFF26453A);

  /// Saga Riak — aksen utama (tombol, progres, angka penting).
  static const Color ripple = Color(0xFFFF6B3D);
  static const Color rippleShadow = Color(0xFFC24A22);

  /// Terverifikasi — hijau bukti dampak / status sukses.
  static const Color verified = Color(0xFF3DDC97);
  static const Color verifiedText = Color(0xFF0D8A58);

  /// Kertas Kas — latar hangat seperti kuitansi.
  static const Color paper = Color(0xFFF6F1E7);
  static const Color paperOuter = Color(0xFFEDE6D6);
  static const Color paperDeep = Color(0xFFEADFC9);
  static const Color border = Color(0xFFCFC3A7);

  /// Nama lama dipertahankan agar seluruh layar lama tetap kompilasi.
  static const Color primary = ink;
  static const Color secondary = ripple;
  static const Color background = paper;
  static const Color surface = Colors.white;
  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF5C6A62);
  static const Color error = Color(0xFFC24A22);
  static const Color success = verified;
  static const Color warning = Color(0xFFB59A62);
}
