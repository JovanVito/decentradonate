import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_config.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) => supabaseClient);
