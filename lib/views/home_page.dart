/// 홈 화면 — 회차별 풀이 / 영역별 모아풀기 탭.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/categories.dart';
import '../data/data_loader.dart';
import '../models/models.dart';
import '../state/store.dart';
import '../theme.dart';
import '../widgets/progress_track.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  Future<IndexFile>? _idxFuture;

  @override
  void initState() {
    super.initState();
    final initial = Store.instance.getHomeTab() == 'cats' ? 1 : 0;
    _tab = TabController(length: 2, vsync: this, initialIndex: initial);
    _tab.addListener(() {
      if (_tab.indexIsChanging) return;
      Store.instance.setHomeTab(_tab.index == 1 ? 'cats' : 'exams');
    });
    _idxFuture = DataLoader.instance.loadIndex();
    Store.instance.addListener(_onStore);
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    Store.instance.removeListener(_onStore);
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 상단 흰색 헤더가 status bar 까지 자연스럽게 이어지도록 body 가
      // 화면 전체를 차지하고 내부 위젯이 SafeArea 를 직접 챙긴다.
      body: FutureBuilder<IndexFile>(
        future: _idxFuture,
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.hasError) {
              return SafeArea(
                  child: Center(child: Text('로드 실패: ${snap.error}')));
            }
            return const SafeArea(
                child: Center(child: CircularProgressIndicator()));
          }
          final idx = snap.data!;
          return _buildShell(context, idx);
        },
      ),
    );
  }

  Widget _buildShell(BuildContext context, IndexFile idx) {
    // Overall progress
    int total = 0;
    int answered = 0;
    for (final e in idx.exams) {
      total += e.totalQuestions;
      answered += Store.instance.getProgress(e.id).length +
          Store.instance.getListenProgress(e.id).length;
    }
    final overall = total == 0 ? 0 : ((answered / total) * 100).round();
    final last = Store.instance.getLast();
    final wbCount = Store.instance.getWordbook().length;

    return Column(
      children: [
        Material(
          color: appBg,
          child: SafeArea(
            bottom: false,
            child: _topBar(context,
                total: total,
                answered: answered,
                overall: overall,
                wbCount: wbCount,
                last: last),
          ),
        ),
        // 세그먼티드 칩 — TabBar 의 underline 보다 1020 톤에 어울리는 pill UI
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: _segmentedTabs(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _examTab(context, idx),
              _catTab(context, idx),
            ],
          ),
        ),
      ],
    );
  }

  Widget _segmentedTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: AnimatedBuilder(
        animation: _tab,
        builder: (context, _) {
          return Row(
            children: [
              Expanded(child: _segChip('회차별 풀이', 0)),
              Expanded(child: _segChip('영역별 모아풀기', 1)),
            ],
          );
        },
      ),
    );
  }

  Widget _segChip(String label, int index) {
    final active = _tab.index == index;
    return GestureDetector(
      onTap: () => _tab.animateTo(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        decoration: BoxDecoration(
          color: active ? brandPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : ink2,
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, {
    required int total,
    required int answered,
    required int overall,
    required int wbCount,
    LastPos? last,
  }) {
    // 슬림 헤더 — 한 줄에 로고 / 진도칩 / 액션. 큰 progress 카드 제거.
    return Container(
      color: appBg,
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 로고 칩
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: brandGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33FF3366),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🍒', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 6),
                    Text(
                      '엔원노트',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 인라인 미니 진도 칩 — 진도바 + 숫자 한 줄
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$answered/$total',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: brandPrimary,
                              )),
                          Text('$overall%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: textMuted,
                                fontWeight: FontWeight.w800,
                              )),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ProgressTrack(
                        progress: total == 0 ? 0 : answered / total,
                        color: brandPrimary,
                        height: 4,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _iconChip(
                icon: Icons.star_rounded,
                color: gold,
                badge: wbCount > 0 ? '$wbCount' : null,
                onTap: () => context.push('/wordbook'),
              ),
              const SizedBox(width: 4),
              _iconChip(
                icon: Icons.refresh_rounded,
                color: textMuted,
                onTap: _confirmReset,
              ),
            ],
          ),
          if (last != null) ...[
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push(
                  '/exam/${last.examId}/q/${last.questionN}'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: brandSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: brandPrimary.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    const Text('이어서 풀기',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: brandPrimary,
                        )),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '문제 ${last.questionN}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: textMuted,
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconChip({
    required IconData icon,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              if (badge != null)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: brandPrimary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBg, width: 2),
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    child: Text(
                      badge,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('진도 초기화'),
        content: const Text(
            '회차별 풀이 진도와 청해 진도가 모두 지워집니다.\n단어장 ★ 표시는 그대로 유지됩니다.\n진행할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('초기화')),
        ],
      ),
    );
    if (ok == true) await Store.instance.clearAllProgress();
  }

  Widget _examTab(BuildContext context, IndexFile idx) {
    final bottomSafe = MediaQuery.of(context).viewPadding.bottom;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 48 + bottomSafe),
      itemCount: idx.exams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final e = idx.exams[i];
        final readProg = Store.instance.getProgress(e.id);
        final listenProg = Store.instance.getListenProgress(e.id);
        final totalQ = e.totalQuestions;
        final answered = readProg.length + listenProg.length;
        final correct = readProg.values.where((r) => r.correct).length +
            listenProg.values.where((r) => r.correct).length;
        final progress = totalQ == 0 ? 0.0 : answered / totalQ;
        final accuracy =
            answered == 0 ? 0 : ((correct / answered) * 100).round();
        final done = totalQ > 0 && answered == totalQ;
        // 회차 짧은 라벨 (Mock Test prefix 제거)
        final short = e.title
            .replaceAll(RegExp(r'^JLPT N1 Mock Test\s*[–-]\s*',
                caseSensitive: false), '')
            .trim();
        return Material(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => context.push('/exam/${e.id}'),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cardBorder),
                boxShadow: softShadow,
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 좌측 그라데이션 큰 칩
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: brandGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33FF3366),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text('📘',
                        style: TextStyle(fontSize: 30)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                short,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                  color: ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (done)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: okSoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('완료',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: ok,
                                      fontWeight: FontWeight.w900,
                                    )),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '독해 ${e.questions} · 청해 ${e.listeningQuestions} · ${e.passages}지문',
                          style: const TextStyle(
                              fontSize: 11, color: textMuted),
                        ),
                        const SizedBox(height: 10),
                        ProgressTrack(
                            progress: progress,
                            color: brandPrimary,
                            height: 6),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('$answered/$totalQ',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: brandPrimary,
                                )),
                            const SizedBox(width: 6),
                            const Text('•',
                                style:
                                    TextStyle(fontSize: 11, color: textMuted)),
                            const SizedBox(width: 6),
                            Text('정답률 $accuracy%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: textMuted,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _catTab(BuildContext context, IndexFile idx) {
    final byGroup = <CategoryGroup, List<CategoryDef>>{};
    for (final c in allCategories) {
      (byGroup[c.group] ??= []).add(c);
    }
    final bottomSafe = MediaQuery.of(context).viewPadding.bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 48 + bottomSafe),
      children: byGroup.entries.map((g) {
        final isListen = g.key == CategoryGroup.listening;
        final groupColor = isListen ? listeningPrimary : brandPrimary;
        final groupSoft = isListen ? listeningSurface : brandSurface;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: groupSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        g.key.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: groupColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${g.value.length}개 영역',
                      style: const TextStyle(
                          fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.1,
                children: g.value.map((c) {
                  final total = idx.categoryTotals[c.category] ?? 0;
                  final examId = 'cat:${c.slug}';
                  final prog = Store.instance.getProgress(examId);
                  final answered = prog.length;
                  final pct = total == 0
                      ? 0
                      : ((answered / total) * 100).round();
                  return Material(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.push('/exam/$examId'),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardBorder),
                          boxShadow: softShadow,
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 상단: 진도 칩 (% 또는 NEW)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: answered > 0 ? groupColor : groupSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                answered > 0 ? '$pct%' : 'NEW',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: answered > 0
                                      ? Colors.white
                                      : groupColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              categoryKo(c.category),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                                color: ink,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (total > 0)
                              ProgressTrack(
                                progress: answered / total,
                                color: groupColor,
                                height: 4,
                              ),
                            const SizedBox(height: 4),
                            Text(
                              total == 0
                                  ? '$total문제'
                                  : '$answered / $total',
                              style: const TextStyle(
                                fontSize: 11,
                                color: textMuted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
