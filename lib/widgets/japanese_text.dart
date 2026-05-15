/// 일본어 텍스트를 vocab-match로 토크나이즈해서 표시.
///
/// 두 가지 시각 강조를 명확히 구분:
///  - **vocab 매치 단어 (탭→사전)**: 옅은 파란 글자 + 옅은 노란 하이라이트
///    (밑줄 없음). "탭해서 뜻 볼 수 있음" 만 암시.
///  - **출제 어휘 (stem_u, 한자읽기 문제의 대상 단어)**: 굵은 검정 글자 + 두꺼운
///    빨강 솔리드 밑줄. 시험에서 "이 단어를 봐 달라" 는 강한 신호.
///    이 구간 안의 vocab 매치는 파란색 대신 검정 굵게 유지하되 탭은 가능.
///
/// 후리가나 ON 시: 매치된 단어 뒤에 작은 회색 (가나) 를 인라인 표시 — 줄높이가
/// 들쭉날쭉해지지 않도록 widget-span ruby 대신 inline () 사용.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/vocab_match.dart';
import '../models/models.dart';

class JapaneseText extends StatelessWidget {
  final String text;
  final VocabIndex index;
  final bool furigana;
  final TextStyle? baseStyle;
  final String? underline; // stem_u — 이 부분만 밑줄
  final void Function(VocabEntry entry)? onWordTap;

  const JapaneseText({
    super.key,
    required this.text,
    required this.index,
    required this.furigana,
    this.baseStyle,
    this.underline,
    this.onWordTap,
  });

  // Visual tokens — vocab 와 출제 어휘를 확실히 구분하는 두 가지 강조.
  static const _vocabColor = Color(0xFF1D4ED8);
  static const _vocabBg = Color(0x261D4ED8); // 15% blue tint
  static const _targetColor = Color(0xFF111827);
  static const _targetUnderline = Color(0xFFB91C1C); // red-700

  @override
  Widget build(BuildContext context) {
    final style = baseStyle ??
        const TextStyle(fontSize: 16, height: 1.7, color: Color(0xFF111827));

    final under = underline;
    if (under != null && under.isNotEmpty) {
      final i = text.indexOf(under);
      if (i >= 0) {
        final before = text.substring(0, i);
        final mid = text.substring(i, i + under.length);
        final after = text.substring(i + under.length);
        final targetStyle = style.copyWith(
          color: _targetColor,
          fontWeight: FontWeight.w800,
          decoration: TextDecoration.underline,
          decorationThickness: 2.6,
          decorationColor: _targetUnderline,
        );
        return Text.rich(
          TextSpan(
            style: style,
            children: [
              ..._buildSpans(before, style, inTarget: false),
              ..._buildSpans(mid, targetStyle, inTarget: true),
              ..._buildSpans(after, style, inTarget: false),
            ],
          ),
        );
      }
    }

    return Text.rich(
      TextSpan(
        style: style,
        children: _buildSpans(text, style, inTarget: false),
      ),
    );
  }

  List<InlineSpan> _buildSpans(String src, TextStyle style,
      {required bool inTarget}) {
    if (src.isEmpty) return const [];
    final segs = matchVocab(src, index);
    final spans = <InlineSpan>[];
    for (final s in segs) {
      if (s.entry == null) {
        spans.add(TextSpan(text: s.text, style: style));
      } else {
        spans.add(_wordSpan(s.entry!, style, inTarget: inTarget));
      }
    }
    return spans;
  }

  InlineSpan _wordSpan(VocabEntry e, TextStyle style,
      {required bool inTarget}) {
    final tap = TapGestureRecognizer()
      ..onTap = () {
        if (onWordTap != null) onWordTap!(e);
      };

    // 출제 어휘(stem_u) 구간 안의 vocab 매치 — target 스타일을 유지하되 탭만 받음.
    // 색/굵기/밑줄을 덮어쓰지 않아 출제 어휘의 시각적 강조가 깨지지 않는다.
    if (inTarget) {
      if (!furigana || e.r.isEmpty || e.r == e.w) {
        return TextSpan(text: e.w, style: style, recognizer: tap);
      }
      return TextSpan(
        style: style,
        recognizer: tap,
        children: [
          TextSpan(text: e.w),
          TextSpan(
            text: '(${e.r})',
            style: style.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: (style.fontSize ?? 16) * 0.72,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      );
    }

    // 일반 본문의 vocab 단어 — 파란 글자 + 옅은 파란 배경 (밑줄 없음).
    final wordStyle = style.copyWith(
      color: _vocabColor,
      fontWeight: FontWeight.w600,
      background: Paint()..color = _vocabBg,
    );

    if (!furigana || e.r.isEmpty || e.r == e.w) {
      return TextSpan(text: e.w, style: wordStyle, recognizer: tap);
    }
    return TextSpan(
      style: wordStyle,
      recognizer: tap,
      children: [
        TextSpan(text: e.w),
        TextSpan(
          text: '(${e.r})',
          style: style.copyWith(
            color: const Color(0xFF6B7280),
            fontSize: (style.fontSize ?? 16) * 0.72,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
