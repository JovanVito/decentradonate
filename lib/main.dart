import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

/// Entry point.
/// `ProviderScope` WAJIB membungkus root widget — ini yang menyimpan
/// semua state Riverpod untuk seluruh lifetime aplikasi.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DecentradonateApp()));
}
