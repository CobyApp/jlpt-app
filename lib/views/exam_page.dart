/// 회차 / 카테고리 진입 화면 — 영역(섹션) 다중선택.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/categories.dart';
import '../data/data_loader.dart';
import '../models/models.dart';
import '../state/store.dart';
import '../theme.dart';
import 'category_listening_page.dart';

class _Section {
  final String key;
  final int from;
  final int to;
  final int idx;
  _Section(this.key, this.from, this.to, this.idx);
  int get count => to - from + 1;
}

class ExamPage extends StatefulWidget {
  final String examId;
  const ExamPage({super.key, required this.examId});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  Future<Exam>? _examF;
  final Set<String> _selected = {};

  bool get _isCategoryDrill => widget.examId.startsWith('cat:');

  @override
  void initState() {
    super.initState();
    // 청해 카테고리는 별도 화면.
    if (_isCategoryDrill &&
        listeningSlugs.contains(widget.examId.substring(4))) {
      // 빌드 후 분기 — 여기는 빈 build로 두고 build()에서 처리.
    }
    _examF = DataLoader.instance.loadExam(widget.examId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCategoryDrill &&
        listeningSlugs.contains(widget.examId.substring(4))) {
      return CategoryListeningPage(slug: widget.examId.substring(4));
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(_isCategoryDrill ? 'Category Drill' : 'Exam Overview',
            style: const TextStyle(fontSize: 14, color: textMuted)),
      ),
      body: FutureBuilder<Exam>(
        future: _examF,
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.hasError) {
              return Center(child: Text('로드 실패: ${snap.error}'));
            }
            return const Center(child: CircularProgressIndicator());
          }
          return _buildBody(context, snap.data!);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, Exam exam) {
    final keyOf =
        _isCategoryDrill ? (Question q) => q.srcLabel ?? '' : (Question q) => q.category;
    final sections = _groupSections(exam.questions, keyOf);

    final groupCatMap = <String, CategoryGroup>{};
    for (final c in allCategories) {
      groupCatMap[c.category] = c.group;
    }

    final byGroup = <CategoryGroup, List<_Section>>{};
    for (final s in sections) {
      final g = _isCategoryDrill
          ? CategoryGroup.reading
          : (groupCatMap[s.key] ?? CategoryGroup.reading);
      (byGroup[g] ??= []).add(s);
    }
    final orderedGroups = [
      CategoryGroup.vocab,
      CategoryGroup.grammar,
      CategoryGroup.reading,
    ];

    final listenSubs = exam.listening?.subsections ?? const <ListeningSubsection>[];
    final readingQs = exam.questions.length;
    final listenQs = listenSubs.fold<int>(0, (s, x) => s + x.questions.length);
    final totalQ = readingQs + listenQs;
    final totalListenAns = Store.instance.getListenProgress(exam.testId).length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              _hero(exam, readingQs, listenQs, totalQ),
              // hero → 액션 행 간격 최소화 (영역별에서 너무 멀어 보이던 문제)
              const SizedBox(height: 10),
              Row(
                children: [
                  if (!_isCategoryDrill)
                    Expanded(
                      child: FilledButton(
                        onPressed: () => context.push(
                            '/exam/${exam.testId}/q/1?from=1&to=$readingQs'),
                        style: FilledButton.styleFrom(
                          backgroundColor: accentPrimary,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                        ),
                        child: const Text('▶ 전체 시작'),
                      ),
                    )
                  else
                    Expanded(
                      child: TextButton(
                        onPressed: _selected.isEmpty
                            ? null
                            : () => setState(_selected.clear),
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('선택 해제'),
                      ),
                    ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        for (final s in sections) _selected.add(s.key);
                        for (final sub in listenSubs) {
                          _selected.add('listen:${sub.order}');
                        }
                      });
                    },
                    child: const Text('전체 선택'),
                  ),
                ],
              ),
              // 일반 회차에서만 선택 해제 별도 행 (전체 시작 버튼이 위 행에 있어서)
              if (!_isCategoryDrill && _selected.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(_selected.clear),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text('선택 해제'),
                  ),
                ),
              ...(_isCategoryDrill
                  ? [_sectionGroup(context, exam, '회차', sections, isListen: false)]
                  : orderedGroups
                      .where((g) => byGroup.containsKey(g))
                      .map((g) => _sectionGroup(
                          context, exam, g.label, byGroup[g]!,
                          isListen: false))
                      .toList()),
              if (listenSubs.isNotEmpty && !_isCategoryDrill) ...[
                const SizedBox(height: 14),
                _listenGroup(context, exam, listenSubs, totalListenAns, listenQs),
              ],
            ],
          ),
        ),
        _actionBar(context, exam, sections, listenSubs, totalQ),
      ],
    );
  }

  Widget _hero(Exam exam, int readQs, int listenQs, int totalQ) {
    final passages = exam.passages.length;
    // 카테고리 드릴: 제목 + 한 줄 메타만. 일반 회차: 메타 두 줄 (총 문제 + 힌트).
    final total = _isCategoryDrill
        ? '${exam.questions.length}문제 · $passages지문'
        : '총 $totalQ문제 (어휘·문법·독해 $readQs${listenQs > 0 ? ' + 청해 $listenQs' : ''}) · $passages지문';
    // 카테고리 드릴은 짧은 회차 카드 형태로 모이는 화면이라 hint 생략.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exam.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(total,
            style:
                const TextStyle(fontSize: 12, color: textMuted, height: 1.4)),
      ],
    );
  }

  List<_Section> _groupSections(
      List<Question> qs, String Function(Question) keyOf) {
    final out = <_Section>[];
    for (final q in qs) {
      final k = keyOf(q);
      if (out.isNotEmpty && out.last.key == k) {
        out[out.length - 1] = _Section(k, out.last.from, q.n, out.last.idx);
      } else {
        out.add(_Section(k, q.n, q.n, out.length));
      }
    }
    return out;
  }

  Widget _sectionGroup(
    BuildContext context,
    Exam exam,
    String groupLabel,
    List<_Section> list, {
    required bool isListen,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isListen ? listeningSurface : brandSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              groupLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isListen ? listeningPrimary : brandPrimary,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ...list.map((s) {
            final selected = _selected.contains(s.key);
            final label = _isCategoryDrill
                ? s.key
                : categoryKo(s.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _sectionTile(
                number: _isCategoryDrill
                    ? '회차 ${s.idx + 1}'
                    : '問題${s.idx + 1}',
                label: label,
                meta: '${s.from}–${s.to} · ${s.count}문제',
                selected: selected,
                isListen: false,
                onTap: () => setState(() {
                  if (selected) {
                    _selected.remove(s.key);
                  } else {
                    _selected.add(s.key);
                  }
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _listenGroup(
    BuildContext context,
    Exam exam,
    List<ListeningSubsection> subs,
    int answered,
    int totalListen,
  ) {
    final prog = Store.instance.getListenProgress(exam.testId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('청해',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: listeningPrimary,
                  letterSpacing: 0.4,
                )),
            const SizedBox(width: 8),
            Text(
              answered > 0
                  ? '$answered/$totalListen 완료'
                  : '${subs.length}영역 · $totalListen문제',
              style: const TextStyle(fontSize: 11, color: textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...subs.map((sub) {
          final key = 'listen:${sub.order}';
          final selected = _selected.contains(key);
          final answered =
              sub.questions.where((q) => prog.containsKey(q.id)).length;
          final ko = listeningShortKo[sub.type] ?? sub.englishTitle;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _sectionTile(
              number: '問題${sub.order}',
              label: ko,
              meta:
                  '🔊 音声 · ${answered > 0 ? '$answered/${sub.questions.length}문제' : '${sub.questions.length}문제'}',
              selected: selected,
              isListen: true,
              onTap: () => setState(() {
                if (selected) {
                  _selected.remove(key);
                } else {
                  _selected.add(key);
                }
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _sectionTile({
    required String number,
    required String label,
    required String meta,
    required bool selected,
    required bool isListen,
    required VoidCallback onTap,
  }) {
    final accent = isListen ? listeningPrimary : accentPrimary;
    // 선택/미선택에 따라 사이즈가 미세하게 밀리지 않도록 보더 굵기 / 슬롯을
    // 모두 고정. 색만 바뀐다.
    return Material(
      color: selected
          ? (isListen ? listeningPale : accentSoft)
          : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent : cardBorder,
              width: 1.5, // 항상 동일
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? accent : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  number,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(meta,
                        style: const TextStyle(
                            fontSize: 11, color: textMuted)),
                  ],
                ),
              ),
              // 항상 체크아이콘 슬롯을 잡아두고 opacity 로만 토글 — 선택해도 폭이 안 밀림.
              SizedBox(
                width: 18,
                height: 18,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: selected ? 1 : 0,
                  child: Icon(Icons.check_circle, color: accent, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBar(
    BuildContext context,
    Exam exam,
    List<_Section> sections,
    List<ListeningSubsection> listenSubs,
    int totalAll,
  ) {
    final selectedReading =
        sections.where((s) => _selected.contains(s.key)).toList();
    final selectedListen = listenSubs
        .where((s) => _selected.contains('listen:${s.order}'))
        .toList();
    final hasSelection =
        selectedReading.isNotEmpty || selectedListen.isNotEmpty;
    final selCount = selectedReading.fold<int>(0, (s, x) => s + x.count) +
        selectedListen.fold<int>(0, (s, x) => s + x.questions.length);

    String label;
    String range;
    if (!hasSelection) {
      label = '영역을 선택하세요';
      range = '총 $totalAll문제';
    } else {
      final total = selectedReading.length + selectedListen.length;
      if (total == 1) {
        if (selectedReading.length == 1) {
          final s = selectedReading.first;
          label = _isCategoryDrill
              ? s.key
              : '問題${s.idx + 1} ${categoryKo(s.key)}';
          range = '${s.from}–${s.to} · ${s.count}문제';
        } else {
          final m = selectedListen.first;
          label = '청해 問題${m.order} ${listeningShortKo[m.type] ?? ''}'.trim();
          range = '${m.questions.length}문제 (청해)';
        }
      } else {
        label = '$total개 영역 선택';
        final tags = [
          ...selectedReading.map((s) =>
              _isCategoryDrill ? s.key : '問題${s.idx + 1}'),
          ...selectedListen.map((m) => '청해${m.order}'),
        ].join(', ');
        range = '$tags · $selCount문제';
      }
    }

    // 안전영역까지 흰 배경으로 채워서 홈인디케이터 영역이 비치지 않게.
    return Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: cardBorder)),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 4),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: hasSelection
                                ? const Color(0xFF111827)
                                : textMuted,
                          )),
                      const SizedBox(height: 2),
                      Text(range,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: !hasSelection
                      ? null
                      : () {
                          final sectionKeys = [
                            ...selectedReading.map((s) => s.key),
                            ...selectedListen.map((m) => 'listen:${m.order}'),
                          ];
                          final params = sectionKeys.isEmpty
                              ? ''
                              : '?sections=${Uri.encodeQueryComponent(sectionKeys.join(","))}';
                          context
                              .push('/exam/${exam.testId}/words$params');
                        },
                  child: const Text('📖 단어'),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accentPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: !hasSelection
                      ? null
                      : () {
                          if (selectedReading.isEmpty &&
                              selectedListen.isNotEmpty) {
                            final m = selectedListen.first.order;
                            context.push(
                                '/exam/${exam.testId}/listen/$m');
                            return;
                          }
                          final from = selectedReading
                              .map((s) => s.from)
                              .reduce((a, b) => a < b ? a : b);
                          final to = selectedReading
                              .map((s) => s.to)
                              .reduce((a, b) => a > b ? a : b);
                          context.push(
                              '/exam/${exam.testId}/q/$from?from=$from&to=$to');
                        },
                  child: const Text('시작 →'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
