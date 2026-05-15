/// 일본어 텍스트를 vocab-match로 토크나이즈해서 표시.
/// - 단어가 매치된 segment는 탭하면 onWordTap 호출 (popover/sheet 띄우기)
/// - 후리가나 ON: 단어 위에 한자 + 작은 가나(reading) 같이 표시
/// - 단어 영역은 파란 점선 underline으로 클릭 가능함을 표시
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
              ..._buildSpans(before, style, context),
              ..._buildSpans(
                mid,
                style.copyWith(
                  decoration: TextDecoration.underline,
                  decorationThickness: 2,
                  fontWeight: FontWeight.w700,
                ),
                context,
              ),
              ..._buildSpans(after, style, context),
            ],
          ),
        );
      }
    }

    return Text.rich(
      TextSpan(style: style, children: _buildSpans(text, style, context)),
    );
  }

  List<InlineSpan> _buildSpans(
      String src, TextStyle style, BuildContext ctx) {
    if (src.isEmpty) return const [];
    final segs = matchVocab(src, index);
    final spans = <InlineSpan>[];
    for (final s in segs) {
      if (s.entry == null) {
        spans.add(TextSpan(text: s.text, style: style));
      } else {
        spans.add(_wordSpan(s.entry!, style, ctx));
      }
    }
    return spans;
  }

  InlineSpan _wordSpan(VocabEntry e, TextStyle style, BuildContext ctx) {
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

    if (!furigana || e.r.isEmpty || e.r == e.w) {
      return TextSpan(text: e.w, style: wordStyle, recognizer: tap);
    }
    // Show reading above kanji (a simple "ruby" approximation).
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: GestureDetector(
        onTap: () => onWordTap?.call(e),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(right: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e.r,
                style: TextStyle(
                  fontSize: (style.fontSize ?? 16) * 0.55,
                  height: 1.0,
                  color: const Color(0xFF6B7280),
                ),
              ),
              Text(e.w, style: wordStyle.copyWith(height: 1.05)),
            ],
          ),
        ),
      ),
    );
  }
}
