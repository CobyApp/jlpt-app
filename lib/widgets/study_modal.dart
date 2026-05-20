/// 단어 플래시카드 학습 모달 — 루프 방식.
///
/// 흐름:
///  1. 카드 탭 → 뜻 공개
///  2. "몰라요" → 큐 맨 뒤로 이동 (나중에 다시 나옴)
///  3. "알아요" → 큐에서 제거
///  4. 큐가 빌 때까지 반복 → 완료 화면
///
/// SRS 도 함께 갱신: 알아요 = easy, 몰라요 = again.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/store.dart';
import '../theme.dart';

enum StudyOrder { random, weakest, unseen }

class StudyModal extends StatefulWidget {
  final List<VocabEntry> words;
  final Map<String, List<String>> kanjiKo;
  final String title;
  final StudyOrder order;
  const StudyModal({
    super.key,
    required this.words,
    required this.kanjiKo,
    this.title = '단어장 외우기',
    this.order = StudyOrder.weakest,
  });

  static Future<void> open(
    BuildContext context, {
    required List<VocabEntry> words,
    required Map<String, List<String>> kanjiKo,
    String title = '단어장 외우기',
    StudyOrder order = StudyOrder.weakest,
  }) {
    if (words.isEmpty) return Future.value();
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => StudyModal(
          words: words,
          kanjiKo: kanjiKo,
          title: title,
          order: order,
        ),
      ),
    );
  }

  @override
  State<StudyModal> createState() => _StudyModalState();
}

class _StudyModalState extends State<StudyModal>
    with SingleTickerProviderStateMixin {
  // 현재 큐 (앞에서 꺼내 알아요면 제거 / 몰라요면 끝으로).
  late List<VocabEntry> _queue;
  // 통계
  int _totalWords = 0;
  int _knownCount = 0; // 알아요로 큐에서 제거된 수 (= 학습 완료된 단어 수)
  int _unknownTaps = 0; // 몰라요 누른 누적 횟수 (한 단어에 여러 번 가능)
  bool _revealed = false;

  static final _kanjiRe = RegExp(r'[一-龯々ヶ]');

  @override
  void initState() {
    super.initState();
    _queue = _orderWords(widget.words, widget.order);
    _totalWords = _queue.length;
  }

  List<VocabEntry> _orderWords(List<VocabEntry> ws, StudyOrder order) {
    if (order == StudyOrder.random) {
      final list = [...ws]..shuffle(Random());
      return list;
    }
    if (order == StudyOrder.unseen) {
      final unseen = <VocabEntry>[];
      final rest = <VocabEntry>[];
      for (final w in ws) {
        final s = Store.instance.getSrs(w.w);
        if (s.level < 0) {
          unseen.add(w);
        } else {
          rest.add(w);
        }
      }
      unseen.shuffle(Random());
      rest.shuffle(Random());
      return [...unseen, ...rest];
    }
    // weakest
    final annotated =
        ws.map((w) => (w: w, s: Store.instance.getSrs(w.w))).toList();
    annotated.sort((a, b) {
      final la = a.s.level < 0 ? -1 : a.s.level;
      final lb = b.s.level < 0 ? -1 : b.s.level;
      if (la != lb) return la.compareTo(lb);
      return a.s.lastTs.compareTo(b.s.lastTs);
    });
    return annotated.map((x) => x.w).toList();
  }

  Future<void> _onKnow() async {
    if (_queue.isEmpty) return;
    final w = _queue.removeAt(0);
    await Store.instance.recordSrs(w.w, SrsAction.easy);
    if (mounted) {
      setState(() {
        _knownCount++;
        _revealed = false;
      });
    }
  }

  Future<void> _onUnknown() async {
    if (_queue.isEmpty) return;
    // 큐 첫 단어를 맨 뒤로 보낸다 → 다른 카드 보고 나서 다시 등장.
    final w = _queue.removeAt(0);
    _queue.add(w);
    await Store.instance.recordSrs(w.w, SrsAction.again);
    if (mounted) {
      setState(() {
        _unknownTaps++;
        _revealed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _queue.isEmpty;
    final progress = _totalWords == 0 ? 0.0 : (_knownCount / _totalWords);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800)),
            Text(
              done
                  ? '완료'
                  : '$_knownCount / $_totalWords 외움 · ${_queue.length}개 남음',
              style: const TextStyle(fontSize: 11, color: textMuted),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFE5E7EB),
            color: brandPrimary,
            minHeight: 3,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: done ? _finished() : _card(),
      ),
    );
  }

  Widget _finished() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            const Text('전부 외웠어요!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            _statRow('외운 단어', _totalWords, const Color(0xFF15803D)),
            _statRow('몰라요 탭 횟수', _unknownTaps,
                const Color(0xFFB91C1C)),
            const SizedBox(height: 22),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: brandPrimary),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('완료'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, int v, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Text('$v',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: c)),
        ],
      ),
    );
  }

  Widget _card() {
    final w = _queue[0];
    final hanjas = <(String, String, String)>[];
    for (final ch in w.w.split('')) {
      if (!_kanjiRe.hasMatch(ch)) continue;
      final v = widget.kanjiKo[ch];
      if (v == null) continue;
      hanjas.add((ch, v.isNotEmpty ? v[0] : '', v.length > 1 ? v[1] : ''));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _revealed = !_revealed),
              behavior: HitTestBehavior.opaque,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Container(
                  key: ValueKey('${w.w}/$_revealed/${_queue.length}'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          w.w,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _revealed ? (w.r.isEmpty ? '—' : w.r) : '???',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: _revealed
                                ? textMuted
                                : const Color(0xFFD1D5DB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _revealed
                              ? Text(
                                  (w.mKo?.isNotEmpty == true)
                                      ? w.mKo!
                                      : (w.m.isEmpty ? '(의미 없음)' : w.m),
                                  key: const ValueKey('m'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    height: 1.5,
                                  ),
                                )
                              : const Text(
                                  '카드를 탭해서 뜻 보기',
                                  key: ValueKey('hint'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textMuted,
                                  ),
                                ),
                        ),
                        if (_revealed && hanjas.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: hanjas
                                .map((h) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(h.$1,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700)),
                                          const SizedBox(width: 6),
                                          Text(h.$2,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF1D4ED8),
                                                  fontWeight: FontWeight.w700)),
                                          const SizedBox(width: 4),
                                          Text(h.$3,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: textMuted)),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 2 행동 — 몰라요(나중에 다시) / 알아요(완료).
          // 뒤집기 전이라도 양쪽 다 가능 (뒤집기는 학습 도움일 뿐).
          Row(
            children: [
              Expanded(
                child: _srsButton(
                  label: '몰라요',
                  bg: const Color(0xFFFEF2F2),
                  fg: const Color(0xFFB91C1C),
                  onPressed: () {
                    if (!_revealed) setState(() => _revealed = true);
                    _onUnknown();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _srsButton(
                  label: '알아요',
                  bg: const Color(0xFF15803D),
                  fg: Colors.white,
                  onPressed: _onKnow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _srsButton({
    required String label,
    required Color bg,
    required Color fg,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: SizedBox(
          height: 54,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: fg,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
