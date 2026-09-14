import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit.dart';
import 'package:fluent_learning/features/learning_unit/recommend/learning_unit_recommender.dart';

LearningUnit _unit({
  required String id,
  required String title,
  LearningUnitStatus status = LearningUnitStatus.active,
  DateTime? due,
  DateTime? updatedAt,
  double percent = 0,
}) {
  final now = DateTime(2026, 9, 14, 12);
  return LearningUnit(
    id: id,
    title: title,
    status: status,
    schedule: LearningUnitSchedule(dueDate: due),
    progress: LearningUnitProgress(percent: percent),
    createdAt: now.subtract(const Duration(days: 10)),
    updatedAt: updatedAt ?? now.subtract(const Duration(days: 5)),
  );
}

void main() {
  const recommender = LearningUnitRecommender();
  final now = DateTime(2026, 9, 14, 12);

  test('returns a one-line reason and prefers overdue units', () {
    final overdue = _unit(
      id: 'a',
      title: 'Overdue',
      due: now.subtract(const Duration(days: 1)),
      percent: 0.2,
    );
    final recent = _unit(
      id: 'b',
      title: 'Recent',
      updatedAt: now.subtract(const Duration(hours: 2)),
      percent: 0.4,
    );
    final done = _unit(
      id: 'c',
      title: 'Done',
      status: LearningUnitStatus.completed,
      percent: 1,
    );

    final recs = recommender.recommend(
      [recent, overdue, done],
      now: now,
    );
    expect(recs.map((e) => e.unit.id).toList(), ['a', 'b']);
    expect(recs.first.reason, '已逾期，优先完成');
    expect(recs.last.reason, '最近学过，尚未完成');
  });

  test('near-due reason within one day', () {
    final unit = _unit(
      id: 'n',
      title: 'Soon',
      due: now.add(const Duration(hours: 12)),
    );
    expect(recommender.reasonFor(unit, now: now), '即将到期');
  });
}
