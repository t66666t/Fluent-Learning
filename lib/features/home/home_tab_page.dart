import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/features/learning_unit/data/learning_unit_repository.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit.dart';
import 'package:fluent_learning/features/learning_unit/pages/create_learning_unit_page.dart';
import 'package:fluent_learning/features/learning_unit/pages/learning_unit_detail_page.dart';
import 'package:fluent_learning/features/learning_unit/recommend/learning_unit_recommender.dart';

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
      body: Consumer<LearningUnitRepository>(
        builder: (context, repo, _) {
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
                emptyHint: '创建学习单元后将在此推荐未完成与临近截止的内容',
                children: recommended
                    .map(
                      (u) => _UnitCard(
                        unit: u,
                        onTap: () => _openUnit(context, u.id),
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

class _HomeSection extends StatelessWidget {
  const _HomeSection({
    required this.title,
    required this.emptyHint,
    required this.children,
  });

  final String title;
  final String emptyHint;
  final List<Widget> children;

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
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              emptyHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white54,
                  ),
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
  const _UnitCard({required this.unit, required this.onTap});

  final LearningUnit unit;
  final VoidCallback onTap;

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
