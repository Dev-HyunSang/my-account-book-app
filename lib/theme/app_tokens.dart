import 'package:flutter/material.dart';

class AppTokens {
  AppTokens._();

  static const paper = Color(0xFFF6F1E7);
  static const paperDeep = Color(0xFFEDE6D6);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF13193A);
  static const ink2 = Color(0xFF41476B);
  static const ink3 = Color(0xFF757A9B);
  static const ink4 = Color(0xFFA8ABC2);
  static const divider = Color(0x1413193A);

  static const stamp = Color(0xFFC8351F);
  static const stampSoft = Color(0xFFF4D9D2);
  static const amber = Color(0xFFE8B547);
  static const amberSoft = Color(0xFFFAEED1);

  static const income = Color(0xFF2F8F5C);
  static const incomeSoft = Color(0xFFDCEEDF);
  static const expense = Color(0xFFD14343);
  static const expenseSoft = Color(0xFFF8DCD8);

  static const onInk = Color(0xFFFFFCF3);

  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 24.0;

  static const shadowSm = <BoxShadow>[
    BoxShadow(color: Color(0x0A3F2F15), blurRadius: 1, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A3F2F15), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const shadowMd = <BoxShadow>[
    BoxShadow(color: Color(0x0A3F2F15), blurRadius: 2, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0F3F2F15), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const shadowStamp = <BoxShadow>[
    BoxShadow(color: Color(0x4DC8351F), blurRadius: 16, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x33C8351F), blurRadius: 4, offset: Offset(0, 2)),
  ];
}
