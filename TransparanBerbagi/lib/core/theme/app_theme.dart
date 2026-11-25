import 'package:material_ui/material_ui.dart';

abstract final class AppTheme {
  static final light = _build(
    ColorScheme.fromSeed(
      seedColor: const Color(0xff006b59),
      primary: const Color(0xff006b59),
      onPrimary: Colors.white,
      surface: const Color(0xfff7faf7),
      onSurface: const Color(0xff18251f),
    ),
  );
  static final dark = _build(
    ColorScheme.fromSeed(
      seedColor: const Color(0xff006b59),
      brightness: Brightness.dark,
      primary: const Color(0xff7ed7bd),
      onPrimary: const Color(0xff00382e),
      surface: const Color(0xff101c17),
      onSurface: const Color(0xffe1ede6),
    ),
  );

  static ThemeData _build(ColorScheme colors) {
    final base = ThemeData(useMaterial3: true, colorScheme: colors);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(fontSize: 28),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontSize: 20),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: buttonShape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
