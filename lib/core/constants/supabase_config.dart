import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static const emailRedirectTo = 'io.supabase.decentradonate://login-callback/';

  static String get key => publishableKey.isNotEmpty
      ? publishableKey
      : String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      url.startsWith('https://') &&
      key.isNotEmpty &&
      (key.startsWith('sb_publishable_') || key.startsWith('eyJ'));
}

SupabaseClient? supabaseClient;
