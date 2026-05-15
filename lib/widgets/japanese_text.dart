/// 일본어 텍스트를 vocab-match로 토크나이즈해서 표시.
/// - 단어가 매치된 segment 는 탭하면 onWordTap 호출 (popover/sheet)
/// - 후리가나 ON: 매치된 단어 뒤에 (작은 가나) 를 인라인 표시.
///   - 위에 ruby 를 띄우면 줄높이가 들쭉날쭉해지므로,
///     안정적인 줄정렬을 위해 inline () 방식을 사용.
/// - 매치된 단어는 파란 점선 underline 으로 클릭 가능함을 표시.
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
        return Text.rich(
          TextSpan(
            style: style,
            children: [
              ..._buildSpans(before, style),
              ..._buildSpans(
                mid,
                style.copyWith(
                  decoration: TextDecoration.underline,
                  decorationThickness: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ..._buildSpans(after, style),
            ],
          ),
        );
      }
    }

    return Text.rich(
      TextSpan(style: style, children: _buildSpans(text, style)),
    );
  }

  List<InlineSpan> _buildSpans(String src, TextStyle style) {
    if (src.isEmpty) return const [];
    final segs = matchVocab(src, index);
    final spans = <InlineSpan>[];
    for (final s in segs) {
      if (s.entry == null) {
        spans.add(TextSpan(text: s.text, style: style));
      } else {
        spans.add(_wordSpan(s.entry!, style));
      }
    }
    return spans;
  }

  InlineSpan _wordSpan(VocabEntry e, TextStyle style) {
    final tap = TapGestureRecognizer()
      ..onTap = () {
        if (onWordTap != null) onWordTap!(e);
      };
    final wordStyle = style.copyWith(
      color: const Color(0xFF1D4ED8),
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
      decorationColor: const Color(0x551D4ED8),
    );

    // 후리가나 OFF, 또는 reading 이 단어와 같거나 비어있으면 그냥 단어만.
    if (!furigana || e.r.isEmpty || e.r == e.w) {
      return TextSpan(text: e.w, style: wordStyle, recognizer: tap);
    }
    // 후리가나 ON — 단어 뒤에 작은 (가나) 를 인라인으로.
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
