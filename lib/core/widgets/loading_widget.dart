import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

/// Widget loading yang REUSABLE — dipakai di Home, Wallet, Upload Proof, dll.
/// Kenapa satu widget saja? Supaya visual "loading" konsisten di seluruh app,
/// dan kalau mau ganti jadi shimmer/skeleton nanti, cukup edit 1 file.
class LoadingWidget extends StatelessWidget {
  final String message;

  const LoadingWidget({super.key, this.message = AppStrings.loading});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
