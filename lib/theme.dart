/// JLPT 앱 테마 — 1020 타겟의 모던 한국 앱 톤.
///   · 비비드 보라 메인 (#7C3AED) + 청해 브라이트 블루 (#3B82F6)
///   · 따뜻한 오프화이트 배경 + 부드러운 카드 그림자
///   · 큰 라운드(18~22) + 굵은 디스플레이 타이포 + 이모지 액센트
library;

import 'package:flutter/material.dart';

// ── 색 토큰 ───────────────────────────────────────────────
const Color brandPrimary = Color(0xFF7C3AED); // violet-600
const Color brandDeep = Color(0xFF6D28D9); // violet-700 (hover/press)
const Color brandSoft = Color(0xFFEDE9FE); // violet-100 (bg tint)
const Color brandSurface = Color(0xFFF5F3FF); // violet-50 (chip bg)

const Color listeningPrimary = Color(0xFF3B82F6); // blue-500
const Color listeningDeep = Color(0xFF2563EB); // blue-600
const Color listeningPale = Color(0xFFDBEAFE); // blue-100
const Color listeningSurface = Color(0xFFEFF6FF); // blue-50

const Color gold = Color(0xFFFBBF24); // ★ 단어장
const Color goldSoft = Color(0xFFFEF3C7);

const Color ok = Color(0xFF10B981); // emerald-500
const Color okSoft = Color(0xFFD1FAE5);

const Color danger = Color(0xFFEF4444); // red-500
const Color dangerSoft = Color(0xFFFEE2E2);

const Color ink = Color(0xFF0F0F12);
const Color ink2 = Color(0xFF1F1F25);
const Color textMuted = Color(0xFF6B7280);

const Color appBg = Color(0xFFFAF9F7);
const Color cardBg = Color(0xFFFFFFFF);
const Color cardBorder = Color(0xFFEEEAF6); // 살짝 보라 기운

// ── 레거시 alias (기존 코드 호환) ─────────────────────────────
const Color accentPrimary = brandPrimary;
const Color accentSoft = brandSoft;

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: brandPrimary,
      brightness: Brightness.light,
      primary: brandPrimary,
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: appBg,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: ink,
      displayColor: ink,
    ),
    cardTheme: CardThemeData(
      color: cardBg,
      surfaceTintColor: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: cardBorder),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: appBg,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE5E1F0),
        disabledForegroundColor: const Color(0xFF9CA3AF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink2,
        side: const BorderSide(color: cardBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: brandPrimary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

/// 카드/박스에 공통으로 쓰는 부드러운 그림자.
const List<BoxShadow> softShadow = [
  BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 18,
    offset: Offset(0, 6),
  ),
];

/// 메인 CTA 그라데이션 (보라). FilledButton 안에 직접 못 쓰니까
/// Ink + Container 조합으로 큰 버튼/배지 만들 때 활용.
const LinearGradient brandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
);

const LinearGradient listeningGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
);
