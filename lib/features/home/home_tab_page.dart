import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/app/main_shell.dart';
import 'package:fluent_learning/features/learning_unit/data/learning_unit_repository.dart';
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

  void _goLibrary() {
    mainShellTabRequest.value = MainShellTab.library;
  }

  bool _libraryHasMedia(LibraryService library) {
    return library.videosForSyncMetadata.any((v) => !v.isRecycled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('首页'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => _openCreate(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新建单元'),
            style: TextButton.styleFrom(foregroundColor: Colors.lightBlueAccent),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer2<LearningUnitRepository, LibraryService>(
        builder: (context, repo, library, _) {
          if (repo.units.isEmpty) {
            return _EmptyHome(
              hasMedia: _libraryHasMedia(library),
              onCreate: () => _openCreate(context),
              onGoLibrary: _goLibrary,
            );
          }

          final continueUnits = repo.units
              .where(
                (u) =>
                    u.status == LearningUnitStatus.active ||
                    u.status == LearningUnitStatus.paused,
              )
              .take(6)
              .toList();
          final recommended = _recommender.recommend(repo.units);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (repo.lastError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    repo.lastError!,
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  ),
                ),
              _HomeSection(
                title: '继续学',
                emptyHint: '暂无进行中的学习单元',
                children: continueUnits
                    .map(
                      (u) => _UnitCard(
                        unit: u,
                        onTap: () => _openUnit(context, u.id),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              _HomeSection(
                title: '推荐',
                emptyHint: '暂无推荐，新建单元开始学习',
                emptyActionLabel: '新建单元',
                onEmptyAction: () => _openCreate(context),
                children: recommended
                    .map(
                      (item) => _UnitCard(
                        unit: item.unit,
                        reason: item.reason,
                        onTap: () => _openUnit(context, item.unit.id),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('新建单元'),
        backgroundColor: const Color(0xFF1E88E5),
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
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            const Text(
              '还没有学习单元',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: Icon(hasMedia ? Icons.auto_awesome : Icons.add),
              label: Text(primaryLabel),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onGoLibrary,
              icon: const Icon(Icons.video_library_outlined, size: 18),
              label: const Text('去媒体库导入'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.lightBlueAccent,
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
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  final String title;
  final String emptyHint;
  final List<Widget> children;
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
              ),
        ),
        const SizedBox(height: 12),
        if (children.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  emptyHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white54,
                      ),
                ),
                if (emptyActionLabel != null && onEmptyAction != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onEmptyAction,
                    child: Text(emptyActionLabel!),
                  ),
                ],
              ],
            ),
          )
        else
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: child,
            ),
          ),
      ],
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.onTap,
    this.reason,
  });

  final LearningUnit unit;
  final VoidCallback onTap;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final due = unit.schedule.dueDate;
    final dueLabel = due == null
        ? unit.status.labelZh
        : '截止 ${due.month}/${due.day} · ${unit.status.labelZh}';
    final pct = (unit.progress.percent * 100).clamp(0, 100).toStringAsFixed(0);

    return Material(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                dueLabel,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              if (reason != null && reason!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  reason!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.lightBlueAccent,
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
                  backgroundColor: Colors.white12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
