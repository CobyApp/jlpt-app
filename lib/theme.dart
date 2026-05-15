/// JLPT 앱 테마. 청해 영역은 파란 계열, 일반 영역은 핑크/액센트.
library;

import 'package:flutter/material.dart';

/// 청해(Listening) 인디케이터로 쓰는 파란 톤.
const Color listeningPrimary = Color(0xFF1D4ED8); // blue-700
const Color listeningLight = Color(0xFF2563EB); // blue-600
const Color listeningPale = Color(0xFFEEF4FF);

/// 일반 영역의 핑크/액센트.
const Color accentPrimary = Color(0xFFD6336C);
const Color accentSoft = Color(0xFFFFE0EC);

/// 회색 톤 카드 배경.
const Color cardBg = Color(0xFFFAFAFB);
const Color cardBorder = Color(0xFFE5E7EB);
const Color textMuted = Color(0xFF6B7280);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accentPrimary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F4F1),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: const Color(0xFF111827),
      displayColor: const Color(0xFF111827),
      fontSizeFactor: 1.0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: cardBorder),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF111827),
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  );
}
