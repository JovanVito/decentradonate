import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/constants/supabase_config.dart';

/// Entry point.
/// `ProviderScope` WAJIB membungkus root widget — ini yang menyimpan
/// semua state Riverpod untuk seluruh lifetime aplikasi.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    supabaseClient = Supabase.instance.client;
  }
  runApp(const ProviderScope(child: DecentradonateApp()));
}
