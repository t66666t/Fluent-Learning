import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit_progress_rules.dart';

void main() {
  group('LearningUnitProgressRules', () {
    test('manual complete is always 100%', () {
      expect(
        LearningUnitProgressRules.itemRatio(
          watchedMs: 10,
          durationMs: 1000,
          manuallyCompleted: true,
        ),
        1.0,
      );
      expect(
        LearningUnitProgressRules.isItemComplete(
          watchedMs: 10,
          durationMs: 1000,
          manuallyCompleted: true,
        ),
        isTrue,
      );
    });

    test('auto-completes at 90%', () {
      expect(
        LearningUnitProgressRules.isItemComplete(
          watchedMs: 899,
          durationMs: 1000,
          manuallyCompleted: false,
        ),
        isFalse,
      );
      expect(
        LearningUnitProgressRules.isItemComplete(
          watchedMs: 900,
          durationMs: 1000,
          manuallyCompleted: false,
        ),
        isTrue,
      );
      expect(
        LearningUnitProgressRules.itemRatio(
          watchedMs: 900,
          durationMs: 1000,
          manuallyCompleted: false,
        ),
        1.0,
      );
    });

    test('unknown duration stays at 0 unless manual', () {
      expect(
        LearningUnitProgressRules.itemRatio(
          watchedMs: 500,
          durationMs: 0,
          manuallyCompleted: false,
        ),
        0.0,
      );
    });

    test('aggregates leaf percents as a mean', () {
      expect(
        LearningUnitProgressRules.aggregatePercent(const [1.0, 0.5]),
        0.75,
      );
      expect(LearningUnitProgressRules.aggregatePercent(const []), 0.0);
    });
  });
}
