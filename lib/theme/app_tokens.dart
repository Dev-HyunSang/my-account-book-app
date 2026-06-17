// 텅장 (Teong-jang) design tokens — Dart mirror of colors_and_type.css + shared.jsx.
// Cream-paper canvas, navy ink, a single 도장-red accent. Pretendard for UI,
// Gmarket Sans for hero numbers and the wordmark.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Color tokens — ground, ink, brand accents, semantic income/expense.
abstract final class TjColors {
  // Ground & ink
  static const paper = Color(0xFFF6F1E7); // cream canvas — outer surface
  static const paperDeep = Color(0xFFEDE6D6); // skeleton / paper-shadow
  static const card = Color(0xFFFFFFFF); // content surface
  static const ink = Color(0xFF13193A); // primary text — navy (never #000)
  static const ink2 = Color(0xFF41476B); // secondary text
  static const ink3 = Color(0xFF757A9B); // tertiary / placeholder
  static const ink4 = Color(0xFFA8ABC2); // disabled / on-cream icon
  static const divider = Color(0x1413193A); // rgba(19,25,58,0.08) hairline
  static const onInk = Color(0xFFFFFCF3); // text on ink surfaces

  // Brand accents
  static const stamp = Color(0xFFC8351F); // 도장 red — totals, brand, add button
  static const stampSoft = Color(0xFFF4D9D2);
  static const amber = Color(0xFFE8B547); // 잉크 amber — recurring badge
  static const amberSoft = Color(0xFFFAEED1);
  static const amberInk = Color(0xFF8B6A1F); // text on amberSoft

  // Semantic — income / expense (expense red is softer than 도장 red)
  static const income = Color(0xFF2F8F5C);
  static const incomeSoft = Color(0xFFDCEEDF);
  static const expense = Color(0xFFD14343);
  static const expenseSoft = Color(0xFFF8DCD8);

  // Weekend accents on the calendar
  static const saturday = Color(0xFF4674C6);

  // Selected-day tints (on ink background)
  static const incomeOnInk = Color(0xFF9FE0BA);
  static const expenseOnInk = Color(0xFFF5B5B0);
}

/// Warm-tinted, layered, low-alpha shadows.
abstract final class TjShadows {
  static const sm = <BoxShadow>[
    BoxShadow(color: Color(0x0A3F2F15), blurRadius: 1, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A3F2F15), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const md = <BoxShadow>[
    BoxShadow(color: Color(0x0A3F2F15), blurRadius: 2, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0F3F2F15), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const lg = <BoxShadow>[
    BoxShadow(color: Color(0x143F2F15), blurRadius: 16, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x1A3F2F15), blurRadius: 32, offset: Offset(0, 16)),
  ];
  static const stampGlow = <BoxShadow>[
    BoxShadow(color: Color(0x4DC8351F), blurRadius: 16, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x33C8351F), blurRadius: 4, offset: Offset(0, 2)),
  ];
}

/// Radii scale.
abstract final class TjRadii {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0; // buttons, inputs
  static const lg = 16.0; // cards
  static const xl = 24.0; // sheets, modals
  static const full = 999.0;
}

const String kFontBody = 'Pretendard';
const String kFontDisplay = 'GmarketSans';

/// Type specimens — Gmarket display + Pretendard body + tabular money.
abstract final class TjType {
  static const display = TextStyle(
    fontFamily: kFontDisplay,
    fontSize: 30,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    color: TjColors.ink,
  );

  static const h1 = TextStyle(
    fontFamily: kFontDisplay,
    fontSize: 24,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.48,
    color: TjColors.ink,
  );

  static const title = TextStyle(
    fontFamily: kFontBody,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.17,
    color: TjColors.ink,
  );

  static const body = TextStyle(
    fontFamily: kFontBody,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: TjColors.ink,
  );

  static const label = TextStyle(
    fontFamily: kFontBody,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.065,
    color: TjColors.ink2,
  );

  static const caption = TextStyle(
    fontFamily: kFontBody,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: TjColors.ink3,
  );

  /// Uppercase eyebrow / section label.
  static const section = TextStyle(
    fontFamily: kFontBody,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.44,
    color: TjColors.ink3,
  );

  /// Monetary — Gmarket, tabular figures, tight tracking.
  static TextStyle money({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = TjColors.ink,
  }) =>
      TextStyle(
        fontFamily: kFontDisplay,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: size * -0.02,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
        height: 1.05,
      );
}

/// Money formatting — mirrors formatWon / formatWonShort.
String formatWon(num n, {bool sign = false}) {
  final abs = n.abs();
  final s = _thousands(abs);
  if (sign) {
    if (n > 0) return '+$s원';
    if (n < 0) return '-$s원';
  }
  return '$s원';
}

String formatWonShort(num n) {
  final abs = n.abs();
  if (abs >= 100000000) {
    final eok = abs / 100000000;
    return '${_trim(eok)}억원';
  }
  if (abs >= 10000) {
    final man = abs / 10000;
    return '${_trim(man)}만원';
  }
  return '${_thousands(abs)}원';
}

String _trim(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(1);
}

String _thousands(num n) {
  final digits = n.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// Category → lucide icon, mirroring CATEGORY_ICONS.
const Map<String, IconData> kCategoryIcons = {
  '월급': LucideIcons.briefcase,
  '부수입': LucideIcons.sparkles,
  '식비': LucideIcons.utensils,
  '교통': LucideIcons.car,
  '주거': LucideIcons.house,
  '구독': LucideIcons.repeat,
  '건강': LucideIcons.stethoscope,
  '쇼핑': LucideIcons.shoppingBag,
};

IconData categoryIcon(String category, {required bool isIncome}) {
  return kCategoryIcons[category] ??
      (isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight);
}

const List<String> kIncomeCategories = ['월급', '부수입'];
const List<String> kExpenseCategories = ['식비', '교통', '주거', '구독', '건강', '쇼핑'];
