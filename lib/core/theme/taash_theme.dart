import 'package:flutter/material.dart';

abstract final class T {
  static const white = Color(0xFFF5F8FF);
  static const paper = Color(0xFF11101F);
  static const surface = Color(0xFF211D34);
  static const ink = Color(0xFFF5F8FF);
  static const muted = Color(0xFFB8ADC9);
  static const coral = Color(0xFFA581FF);
  static const pine = Color(0xFF143C8F);
  static const mint = Color(0xFFC2E4FF);
  static const ochre = Color(0xFFFFCC54);
  static const aubergine = Color(0xFF6934BE);
  static const indigo = Color(0xFF204EBA);
  static const danger = Color(0xFFFF7777);
  static const outline = Color(0xFF443854);
  static const micro = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 240);
  static const game = Duration(milliseconds: 360);

  static ThemeData get theme {
    final colors =
        ColorScheme.fromSeed(
          seedColor: coral,
          brightness: Brightness.dark,
        ).copyWith(
          primary: coral,
          onPrimary: Colors.white,
          secondary: pine,
          surface: paper,
          onSurface: ink,
          error: danger,
          outline: outline,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colors,
      fontFamily: 'DM Sans',
    );
    return base.copyWith(
      scaffoldBackgroundColor: paper,
      textTheme: base.textTheme
          .apply(bodyColor: ink, displayColor: ink)
          .copyWith(
            headlineLarge: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.3,
              color: ink,
            ),
            headlineMedium: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -.7,
              color: ink,
            ),
            titleLarge: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
            bodyMedium: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 15,
              height: 1.45,
              color: ink,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        centerTitle: false,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: coral, width: 2),
        ),
        labelStyle: const TextStyle(color: muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 4,
          shadowColor: const Color(0xff020B26),
          surfaceTintColor: Colors.transparent,
          side: const BorderSide(color: Color(0xffC4ADFF)),
          minimumSize: const Size(48, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 54),
          foregroundColor: ink,
          side: const BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: ink,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: paper,
        showDragHandle: true,
        modalElevation: 8,
      ),
      dividerTheme: const DividerThemeData(color: outline, space: 24),
    );
  }
}
