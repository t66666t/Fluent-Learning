/// Completion / percent aggregation for learning-unit leaf media.
///
/// Default rule: a media item is complete at ≥90% watched **or** when the
/// user marks it complete. Unit percent is the mean of leaf ratios.
abstract final class LearningUnitProgressRules {
  static const double completionRatio = 0.9;

  static double itemRatio({
    required int watchedMs,
    required int durationMs,
    required bool manuallyCompleted,
  }) {
    if (manuallyCompleted) return 1.0;
    if (durationMs <= 0) return 0.0;
    final ratio = watchedMs / durationMs;
    if (ratio >= completionRatio) return 1.0;
    if (ratio <= 0) return 0.0;
    if (ratio >= 1) return 1.0;
    return ratio;
  }

  static bool isItemComplete({
    required int watchedMs,
    required int durationMs,
    required bool manuallyCompleted,
  }) {
    if (manuallyCompleted) return true;
    if (durationMs <= 0) return false;
    return watchedMs / durationMs >= completionRatio;
  }

  static double aggregatePercent(Iterable<double> itemRatios) {
    final list = itemRatios.toList(growable: false);
    if (list.isEmpty) return 0.0;
    var sum = 0.0;
    for (final r in list) {
      sum += r;
    }
    return (sum / list.length).clamp(0.0, 1.0);
  }
}
