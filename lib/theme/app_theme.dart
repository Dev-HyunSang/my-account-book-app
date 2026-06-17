import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// 텅장 theme — an old Korean savings passbook reimagined: cream paper,
/// deep navy ink, a single 도장-red accent. The design is light-first; the
/// dark variant is a calm adaptation that keeps the same accents.
class AppTheme {
  static final ColorScheme _lightScheme = const ColorScheme.light(
    primary: TjColors.ink,
    onPrimary: TjColors.onInk,
    secondary: TjColors.stamp,
    onSecondary: Colors.white,
    surface: TjColors.card,
    onSurface: TjColors.ink,
    error: TjColors.expense,
    outline: TjColors.ink3,
    outlineVariant: TjColors.divider,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: TjColors.ink,
    brightness: Brightness.dark,
    primary: const Color(0xFFCBD2F2),
    secondary: TjColors.stamp,
  );

  static final ThemeData light = _build(
    Brightness.light,
    _lightScheme,
    scaffold: TjColors.paper,
  );

  static final ThemeData dark = _build(
    Brightness.dark,
    _darkScheme,
    scaffold: const Color(0xFF12131A),
  );

  static ThemeData _build(
    Brightness brightness,
    ColorScheme scheme, {
    required Color scaffold,
  }) {
    final isLight = brightness == Brightness.light;
    final onPaper = isLight ? TjColors.ink : scheme.onSurface;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: kFontBody,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _textTheme(onPaper),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TjType.title.copyWith(
          color: onPaper,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: onPaper),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isLight ? TjColors.card : const Color(0xFF1C1D26),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TjRadii.lg),
          side: BorderSide(
            color: isLight ? TjColors.divider : Colors.white12,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: TjColors.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: _inputTheme(isLight),
      filledButtonTheme: FilledButtonThemeData(style: _primaryButton(isLight)),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _primaryButton(isLight)),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: TjColors.ink2,
          textStyle: TjType.label.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? TjColors.ink : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(TjColors.onInk),
        side: const BorderSide(color: TjColors.ink3, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: TjColors.ink,
        contentTextStyle: TjType.body.copyWith(color: TjColors.onInk, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TjRadii.md)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: TjColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TjRadii.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? TjColors.card : const Color(0xFF1C1D26),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TjRadii.xl)),
        titleTextStyle: TjType.title.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
        contentTextStyle: TjType.body.copyWith(color: TjColors.ink2),
      ),
    );
  }

  static TextTheme _textTheme(Color ink) {
    TextStyle b(double size, FontWeight w, {double ls = 0, double h = 1.4}) =>
        TextStyle(
          fontFamily: kFontBody,
          fontSize: size,
          fontWeight: w,
          letterSpacing: ls,
          height: h,
          color: ink,
        );
    return TextTheme(
      headlineLarge: TextStyle(fontFamily: kFontDisplay, fontSize: 28, fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontFamily: kFontDisplay, fontSize: 24, fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.4),
      titleLarge: b(20, FontWeight.w800, ls: -0.4),
      titleMedium: b(17, FontWeight.w700, ls: -0.17),
      bodyLarge: b(16, FontWeight.w400, h: 1.5),
      bodyMedium: b(15, FontWeight.w400, h: 1.5),
      bodySmall: b(13, FontWeight.w500, h: 1.4),
      labelLarge: b(15, FontWeight.w600),
      labelMedium: b(13, FontWeight.w600),
    );
  }

  static InputDecorationTheme _inputTheme(bool isLight) {
    final fill = isLight ? TjColors.card : const Color(0xFF1C1D26);
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(TjRadii.md),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TjType.body.copyWith(color: TjColors.ink3, fontSize: 16),
      labelStyle: TjType.label,
      floatingLabelStyle: TjType.label.copyWith(color: TjColors.ink),
      prefixIconColor: TjColors.ink3,
      suffixIconColor: TjColors.ink3,
      border: border(const Color(0x2913193A), 1.5),
      enabledBorder: border(const Color(0x2913193A), 1.5),
      focusedBorder: border(TjColors.ink, 2),
      errorBorder: border(TjColors.expense, 2),
      focusedErrorBorder: border(TjColors.expense, 2),
      errorStyle: TjType.caption.copyWith(color: TjColors.expense),
    );
  }

  static ButtonStyle _primaryButton(bool isLight) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return TjColors.ink.withValues(alpha: 0.4);
        if (s.contains(WidgetState.pressed)) return const Color(0xFF090C24);
        return TjColors.ink;
      }),
      foregroundColor: const WidgetStatePropertyAll(TjColors.onInk),
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(54)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(TjRadii.md)),
      ),
      textStyle: WidgetStatePropertyAll(
        TjType.title.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: TjColors.onInk),
      ),
    );
  }
}
