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
        // 흰색 헤더가 status bar 영역까지 확장돼서 색 끊김 없이 이어짐.
        Material(
          color: Colors.white,
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
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TabBar(
            controller: _tab,
            indicatorColor: accentPrimary,
            indicatorWeight: 2,
            labelColor: accentPrimary,
            unselectedLabelColor: textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: '회차별 풀이'),
              Tab(text: '영역별 모아풀기'),
            ],
          ),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: TabBarView(
              controller: _tab,
              children: [
                _examTab(context, idx),
                _catTab(context, idx),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topBar(BuildContext context, {
    required int total,
    required int answered,
    required int overall,
    required int wbCount,
    LastPos? last,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('JLPT N1',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: accentPrimary,
                    letterSpacing: 0.4,
                  )),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$answered / $total',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                                Text('$overall%',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: textMuted,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            ProgressTrack(
                              progress: total == 0 ? 0 : answered / total,
                              color: accentPrimary,
                              height: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => context.push('/wordbook'),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFEAB308), size: 26),
                    if (wbCount > 0)
                      Positioned(
                        right: -6,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: accentPrimary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$wbCount',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: '단어장',
              ),
              IconButton(
                onPressed: _confirmReset,
                icon: const Icon(Icons.refresh_rounded,
                    color: textMuted, size: 22),
                tooltip: '진도 초기화',
              ),
            ],
          ),
          if (last != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.push(
                    '/exam/${last.examId}/q/${last.questionN}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_arrow_rounded,
                          color: accentPrimary, size: 18),
                      const SizedBox(width: 4),
                      const Text('이어서',
                          style: TextStyle(
                            fontSize: 12,
                            color: accentPrimary,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${last.examId} · 문제 ${last.questionN}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF8B1538)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_forward,
                          color: accentPrimary, size: 14),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: idx.exams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final e = idx.exams[i];
        final readProg = Store.instance.getProgress(e.id);
        final listenProg = Store.instance.getListenProgress(e.id);
        final totalQ = e.totalQuestions;
        final answered = readProg.length + listenProg.length;
        final correct = readProg.values.where((r) => r.correct).length +
            listenProg.values.where((r) => r.correct).length;
        final progress = totalQ == 0 ? 0.0 : answered / totalQ;
        final accuracy = answered == 0 ? 0 : ((correct / answered) * 100).round();
        final listenMeta =
            e.listeningQuestions > 0 ? ' + 청해 ${e.listeningQuestions}' : '';
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.push('/exam/${e.id}'),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cardBorder),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Mock Test',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: accentPrimary,
                              letterSpacing: 0.6,
                            )),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '총 $totalQ문제 (${e.questions}$listenMeta) · ${e.passages}지문',
                          style: const TextStyle(
                              fontSize: 11, color: textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ProgressTrack(progress: progress, color: accentPrimary),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('$answered/$totalQ 완료',
                          style:
                              const TextStyle(fontSize: 12, color: textMuted)),
                      const Spacer(),
                      Text('정답률 $accuracy%',
                          style:
                              const TextStyle(fontSize: 12, color: textMuted)),
                    ],
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: byGroup.entries.map((g) {
        final isListen = g.key == CategoryGroup.listening;
        final groupColor = isListen ? listeningPrimary : accentPrimary;
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                g.key.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: groupColor,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: g.value.map((c) {
                  final total = idx.categoryTotals[c.category] ?? 0;
                  final examId = 'cat:${c.slug}';
                  final prog = Store.instance.getProgress(examId);
                  final answered = prog.length;
                  final pct = total == 0 ? 0 : ((answered / total) * 100).round();
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => context.push('/exam/$examId'),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isListen
                                ? listeningPrimary.withValues(alpha: 0.18)
                                : cardBorder,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.key.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: groupColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Text(
                                categoryKo(c.category),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            if (total > 0) ...[
                              ProgressTrack(
                                progress: total == 0 ? 0 : answered / total,
                                color: groupColor,
                                height: 4,
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              total == 0
                                  ? '아직 학습 전'
                                  : '$total문제${answered > 0 ? ' · $answered 풀음 ($pct%)' : ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: textMuted,
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
