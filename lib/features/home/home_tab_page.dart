import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/app/main_shell.dart';
import 'package:fluent_learning/app/responsive.dart';
import 'package:fluent_learning/core/theme_tokens.dart';
import 'package:fluent_learning/features/learning_unit/data/learning_unit_repository.dart';
import 'package:fluent_learning/features/learning_unit/due_relative_label.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit.dart';
import 'package:fluent_learning/features/learning_unit/pages/create_learning_unit_page.dart';
import 'package:fluent_learning/features/learning_unit/pages/learning_unit_detail_page.dart';
import 'package:fluent_learning/features/learning_unit/recommend/learning_unit_recommender.dart';
import 'package:fluent_learning/services/library_service.dart';

/// 「首页」Tab — continue / recommend cards + create learning unit.
class HomeTabPage extends StatelessWidget {
  const HomeTabPage({super.key});

  static const LearningUnitRecommender _recommender = LearningUnitRecommender();

  void _openCreate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CreateLearningUnitPage(),
        settings: const RouteSettings(name: '/learning_unit/create'),
      ),
    );
  }

  void _openUnit(BuildContext context, String unitId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LearningUnitDetailPage(unitId: unitId),
        settings: RouteSettings(name: '/learning_unit/$unitId'),
      ),
    );
  }

  /// Primary「继续学」: open execution page; prefer next incomplete via
  /// [LearningUnitDetailPage.autoContinueLearning] → PlaybackNavigation.
  Future<void> _continuePrimary(
    BuildContext context,
    LearningUnit unit,
  ) async {
    final repo = context.read<LearningUnitRepository>();
    final library = context.read<LibraryService>();
    final nextId = repo.nextIncompleteMediaId(unit);
    final canContinue =
        nextId != null && library.getVideo(nextId) != null;

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LearningUnitDetailPage(
          unitId: unit.id,
          autoContinueLearning: canContinue,
        ),
        settings: RouteSettings(name: '/learning_unit/${unit.id}'),
      ),
    );
  }

  void _goLibrary() {
    mainShellTabRequest.value = MainShellTab.library;
  }

  bool _libraryHasMedia(LibraryService library) {
    return library.videosForSyncMetadata.any((v) => !v.isRecycled);
  }

  /// Most recently updated incomplete unit (active → paused → planned).
  LearningUnit? _mostRecentIncomplete(List<LearningUnit> units) {
    final candidates = units.where((u) => u.isIncomplete).toList()
      ..sort((a, b) {
        int rank(LearningUnit u) => switch (u.status) {
              LearningUnitStatus.active => 0,
              LearningUnitStatus.paused => 1,
              LearningUnitStatus.planned => 2,
              _ => 3,
            };
        final byRank = rank(a).compareTo(rank(b));
        if (byRank != 0) return byRank;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return candidates.isEmpty ? null : candidates.first;
  }

  EdgeInsets _listPadding(BuildContext context) {
    if (context.isCompact) {
      return const EdgeInsets.fromLTRB(12, 12, 12, 20);
    }
    if (context.isExpanded) {
      return const EdgeInsets.fromLTRB(24, 20, 24, 32);
    }
    return const EdgeInsets.fromLTRB(16, 16, 16, 24);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('首页'),
        backgroundColor: AppColors.elevated,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => _openCreate(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新建单元'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer2<LearningUnitRepository, LibraryService>(
        builder: (context, repo, library, _) {
          if (repo.units.isEmpty) {
            return _FadeSlideIn(
              child: _EmptyHome(
                hasMedia: _libraryHasMedia(library),
                onCreate: () => _openCreate(context),
                onGoLibrary: _goLibrary,
              ),
            );
          }

          final primary = _mostRecentIncomplete(repo.units);
          final continueOthers = repo.units
              .where(
                (u) =>
                    u.id != primary?.id &&
                    (u.status == LearningUnitStatus.active ||
                        u.status == LearningUnitStatus.paused),
              )
              .take(5)
              .toList();
          final recommended = _recommender.recommend(repo.units);
          final cardPad = _HomeCardMetrics.of(context);

          return _FadeSlideIn(
            child: ListView(
              padding: _listPadding(context),
              children: [
                if (repo.lastError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      repo.lastError!,
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                      ),
                    ),
                  ),
                _HomeSection(
                  title: '继续学',
                  emptyHint: '暂无进行中的学习单元',
                  cardMetrics: cardPad,
                  children: [
                    if (primary != null)
                      _ContinuePrimaryCard(
                        unit: primary,
                        metrics: cardPad,
                        onTap: () => _continuePrimary(context, primary),
                      ),
                    ...continueOthers.map(
                      (u) => _UnitCard(
                        unit: u,
                        metrics: cardPad,
                        onTap: () => _openUnit(context, u.id),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: cardPad.sectionGap),
                _HomeSection(
                  title: '推荐',
                  emptyHint: '暂无推荐，新建单元开始学习',
                  emptyActionLabel: '新建单元',
                  onEmptyAction: () => _openCreate(context),
                  cardMetrics: cardPad,
                  children: recommended
                      .map(
                        (item) => _UnitCard(
                          unit: item.unit,
                          reason: item.reason,
                          requireReason: true,
                          metrics: cardPad,
                          onTap: () => _openUnit(context, item.unit.id),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('新建单元'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
    );
  }
}

/// Responsive card spacing — denser on compact, airier on expanded.
class _HomeCardMetrics {
  const _HomeCardMetrics({
    required this.padding,
    required this.itemGap,
    required this.sectionGap,
    required this.emptyVertical,
  });

  final EdgeInsets padding;
  final double itemGap;
  final double sectionGap;
  final double emptyVertical;

  static _HomeCardMetrics of(BuildContext context) {
    if (context.isCompact) {
      return const _HomeCardMetrics(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 10),
        itemGap: 8,
        sectionGap: 20,
        emptyVertical: 22,
      );
    }
    if (context.isExpanded) {
      return const _HomeCardMetrics(
        padding: EdgeInsets.fromLTRB(18, 16, 18, 14),
        itemGap: 12,
        sectionGap: 28,
        emptyVertical: 32,
      );
    }
    return const _HomeCardMetrics(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 12),
      itemGap: 10,
      sectionGap: 24,
      emptyVertical: 28,
    );
  }
}

/// One-shot fade + slide enter (≤ [AppMotion.emphasized]).
class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({required this.child});

  final Widget child;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.emphasized,
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.standard,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.04),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.standard));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome({
    required this.hasMedia,
    required this.onCreate,
    required this.onGoLibrary,
  });

  final bool hasMedia;
  final VoidCallback onCreate;
  final VoidCallback onGoLibrary;

  @override
  Widget build(BuildContext context) {
    final primaryLabel =
        hasMedia ? '从媒体库生成学习单元' : '新建学习单元';
    final subtitle = hasMedia
        ? '媒体库里已有资料。把它们组成一次学习，进度会跟着播放走。'
        : '把资料库里的媒体组成一次学习，进度会跟着播放走。';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_stories_outlined,
              size: 56,
              color: AppColors.outline,
            ),
            const SizedBox(height: 16),
            const Text(
              '还没有学习单元',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: Icon(hasMedia ? Icons.auto_awesome : Icons.add),
              label: Text(primaryLabel),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.borderMd,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onGoLibrary,
              icon: const Icon(Icons.video_library_outlined, size: 18),
              label: const Text('去媒体库导入'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSection extends StatelessWidget {
  const _HomeSection({
    required this.title,
    required this.emptyHint,
    required this.children,
    required this.cardMetrics,
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  final String title;
  final String emptyHint;
  final List<Widget> children;
  final _HomeCardMetrics cardMetrics;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
        ),
        SizedBox(height: cardMetrics.itemGap + 2),
        if (children.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: cardMetrics.emptyVertical,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.elevated,
              borderRadius: AppRadii.borderMd,
            ),
            child: Column(
              children: [
                Text(
                  emptyHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                if (emptyActionLabel != null && onEmptyAction != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onEmptyAction,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: Text(emptyActionLabel!),
                  ),
                ],
              ],
            ),
          )
        else
          ...children.map(
            (child) => Padding(
              padding: EdgeInsets.only(bottom: cardMetrics.itemGap),
              child: child,
            ),
          ),
      ],
    );
  }
}

/// Primary continue card — one tap opens execution / continue-learning.
class _ContinuePrimaryCard extends StatelessWidget {
  const _ContinuePrimaryCard({
    required this.unit,
    required this.onTap,
    required this.metrics,
  });

  final LearningUnit unit;
  final VoidCallback onTap;
  final _HomeCardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final due = unit.schedule.dueDate;
    final relative = dueRelativeLabel(due);
    final dueLabel = due == null
        ? unit.status.labelZh
        : relative == null
            ? '截止 ${due.month}/${due.day} · ${unit.status.labelZh}'
            : '$relative · ${unit.status.labelZh}';
    final pct = (unit.progress.percent * 100).clamp(0, 100).toStringAsFixed(0);
    final surface = Color.alphaBlend(
      AppColors.primary.withValues(alpha: 0.12),
      AppColors.elevated,
    );

    return Material(
      color: surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: AppRadii.borderMd,
      child: InkWell(
        borderRadius: AppRadii.borderMd,
        hoverColor: AppColors.onSurface.withValues(alpha: 0.06),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        onTap: onTap,
        child: Padding(
          padding: metrics.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.play_circle_filled,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      unit.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                dueLabel,
                style: TextStyle(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '点按继续下一段未完成内容',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: unit.progress.percent.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: AppColors.outlineVariant,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.onTap,
    required this.metrics,
    this.reason,
    this.requireReason = false,
  });

  final LearningUnit unit;
  final VoidCallback onTap;
  final _HomeCardMetrics metrics;
  final String? reason;
  final bool requireReason;

  @override
  Widget build(BuildContext context) {
    final due = unit.schedule.dueDate;
    final relative = dueRelativeLabel(due);
    final dueLabel = due == null
        ? unit.status.labelZh
        : relative == null
            ? '截止 ${due.month}/${due.day} · ${unit.status.labelZh}'
            : '$relative · ${unit.status.labelZh}';
    final pct = (unit.progress.percent * 100).clamp(0, 100).toStringAsFixed(0);
    final reasonLine = (reason == null || reason!.trim().isEmpty)
        ? (requireReason ? '建议继续学习' : null)
        : reason;

    return Material(
      color: AppColors.elevated,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: AppRadii.borderMd,
      child: InkWell(
        borderRadius: AppRadii.borderMd,
        hoverColor: AppColors.onSurface.withValues(alpha: 0.06),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        onTap: onTap,
        child: Padding(
          padding: metrics.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      unit.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                dueLabel,
                style: TextStyle(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
              if (reasonLine != null) ...[
                const SizedBox(height: 4),
                Text(
                  reasonLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: unit.progress.percent.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: AppColors.outlineVariant,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
