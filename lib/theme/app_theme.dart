import 'package:flutter/material.dart';

import 'app_tokens.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppTokens.ink,
      onPrimary: AppTokens.onInk,
      secondary: AppTokens.stamp,
      onSecondary: Colors.white,
      surface: AppTokens.card,
      onSurface: AppTokens.ink,
      error: AppTokens.expense,
    ),
    scaffoldBackgroundColor: AppTokens.paper,
    dividerColor: AppTokens.divider,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppTokens.paper,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppTokens.ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppTokens.ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.17,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppTokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        side: const BorderSide(color: AppTokens.divider),
      ),
    ),
    inputDecorationTheme: _inputTheme(),
    elevatedButtonTheme: _primaryButton(),
    textButtonTheme: _textButton(),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppTokens.stamp,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: CircleBorder(),
    ),
    textTheme: _textTheme(AppTokens.ink),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppTokens.stamp,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121121),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF1C1B2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      ),
    ),
    inputDecorationTheme: _inputTheme(),
    elevatedButtonTheme: _primaryButton(),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppTokens.stamp,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
  );

  static InputDecorationTheme _inputTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppTokens.card,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(
        color: AppTokens.ink2,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      hintStyle: const TextStyle(color: AppTokens.ink3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        borderSide: const BorderSide(color: Color(0x2913193A), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        borderSide: const BorderSide(color: Color(0x2913193A), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        borderSide: const BorderSide(color: AppTokens.ink, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        borderSide: const BorderSide(color: AppTokens.expense, width: 2),
      ),
    );
  }

  static ElevatedButtonThemeData _primaryButton() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTokens.ink,
        foregroundColor: AppTokens.onInk,
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.16,
        ),
      ),
    );
  }

  static TextButtonThemeData _textButton() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppTokens.ink,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color base) {
    return TextTheme(
      displayLarge: TextStyle(
        color: base,
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      headlineMedium: TextStyle(
        color: base,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.42,
      ),
      headlineSmall: TextStyle(
        color: base,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.22,
      ),
      titleLarge: TextStyle(
        color: base,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.18,
      ),
      titleMedium: TextStyle(
        color: base,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: base, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(color: AppTokens.ink2, fontSize: 14, height: 1.5),
      bodySmall: const TextStyle(color: AppTokens.ink3, fontSize: 12),
      labelLarge: TextStyle(
        color: base,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
