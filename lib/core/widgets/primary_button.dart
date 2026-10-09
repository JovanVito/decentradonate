import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Tombol utama gaya "Riak": blok saga dengan bayangan padat 4px
/// sehingga terlihat seperti tombol fisik yang bisa ditekan.
/// Tetap punya loading state untuk mencegah double-tap.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  /// Varian gelap (Tinta Hutan) untuk aksi sekunder seperti "Kirim".
  final bool dark;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppColors.ink : AppColors.ripple;
    final shadow = dark ? Colors.black : AppColors.rippleShadow;
    final disabled = isLoading || onPressed == null;

    return Opacity(
      opacity: disabled && !isLoading ? 0.55 : 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: disabled
              ? null
              : [BoxShadow(color: shadow, offset: const Offset(0, 4))],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: disabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: Colors.white,
              disabledBackgroundColor: bg.withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(label,
                          style: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
