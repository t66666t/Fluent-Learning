import 'package:fluent_learning/features/learning_unit/models/learning_unit.dart';

/// Heuristic recommender for home-tab cards (P1 rules, no ML).
class LearningUnitRecommender {
  const LearningUnitRecommender();

  /// Incomplete units near due date, then recently updated.
  List<LearningUnit> recommend(
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

    if (incomplete.length <= limit) return incomplete;
    return incomplete.sublist(0, limit);
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
