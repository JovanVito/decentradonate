import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget aplikasi.
/// `ConsumerWidget` dipakai (walau belum ada provider di-watch di Stage 1)
/// supaya struktur SUDAH siap untuk Riverpod sejak awal — Stage 2 tinggal
/// menambahkan provider tanpa mengubah root widget lagi.
class DecentradonateApp extends ConsumerWidget {
  const DecentradonateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
