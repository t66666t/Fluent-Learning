import 'package:fluent_learning/features/learning_unit/models/learning_unit.dart';

/// One home-tab recommendation with a one-line reason.
class LearningUnitRecommendation {
  final LearningUnit unit;
  final String reason;

  const LearningUnitRecommendation({
    required this.unit,
    required this.reason,
  });
}

/// Heuristic recommender for home-tab cards (P1 rules, no ML).
class LearningUnitRecommender {
  const LearningUnitRecommender();

  /// Incomplete units near due date, then recently updated.
  List<LearningUnitRecommendation> recommend(
    List<LearningUnit> units, {
    DateTime? now,
    int limit = 8,
  }) {
    final clock = now ?? DateTime.now();
    final incomplete = units.where((u) => u.isIncomplete).toList();

    incomplete.sort((a, b) {
      final scoreA = _score(a, clock);
      final scoreB = _score(b, clock);
      final byScore = scoreB.compareTo(scoreA);
      if (byScore != 0) return byScore;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    final sliced = incomplete.length <= limit
        ? incomplete
        : incomplete.sublist(0, limit);
    return [
      for (final unit in sliced)
        LearningUnitRecommendation(
          unit: unit,
          reason: reasonFor(unit, now: clock),
        ),
    ];
  }

  /// One-line Chinese reason for a recommendation card.
  String reasonFor(LearningUnit unit, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final due = unit.schedule.dueDate;
    if (due != null) {
      final days = due.difference(clock).inHours / 24.0;
      if (days < 0) return '已逾期，优先完成';
      if (days <= 1) return '即将到期';
      if (days <= 3) return '临近截止日期';
    }

    final hoursSinceUpdate = clock.difference(unit.updatedAt).inHours;
    final hasPartialProgress =
        unit.progress.percent > 0 && unit.progress.percent < 1;
    if (hoursSinceUpdate <= 24 && hasPartialProgress) {
      return '最近学过，尚未完成';
    }
    if (hasPartialProgress) {
      return '已有进度，继续完成';
    }
    if (hoursSinceUpdate <= 24) {
      return '最近在学';
    }
    switch (unit.status) {
      case LearningUnitStatus.active:
        return '进行中';
      case LearningUnitStatus.paused:
        return '已暂停，可继续';
      case LearningUnitStatus.planned:
        return '计划中的新单元';
      case LearningUnitStatus.completed:
      case LearningUnitStatus.archived:
        return '建议继续学习';
    }
  }

  double _score(LearningUnit unit, DateTime now) {
    var score = 0.0;

    // Prefer active / paused over planned.
    switch (unit.status) {
      case LearningUnitStatus.active:
        score += 40;
      case LearningUnitStatus.paused:
        score += 25;
      case LearningUnitStatus.planned:
        score += 10;
      case LearningUnitStatus.completed:
      case LearningUnitStatus.archived:
        break;
    }

    final due = unit.schedule.dueDate;
    if (due != null) {
      final days = due.difference(now).inHours / 24.0;
      if (days < 0) {
        // Overdue — highest urgency.
        score += 80 + (-days).clamp(0, 14);
      } else if (days <= 1) {
        score += 70;
      } else if (days <= 3) {
        score += 55;
      } else if (days <= 7) {
        score += 35;
      } else {
        score += 10;
      }
    }

    // Recently touched boost.
    final hoursSinceUpdate = now.difference(unit.updatedAt).inHours;
    if (hoursSinceUpdate <= 24) {
      score += 30;
    } else if (hoursSinceUpdate <= 72) {
      score += 18;
    } else if (hoursSinceUpdate <= 168) {
      score += 8;
    }

    // Partial progress boost.
    if (unit.progress.percent > 0 && unit.progress.percent < 1) {
      score += 15 + unit.progress.percent * 10;
    }

    return score;
  }
}
