import 'package:fluent_learning/features/learning_unit/models/learning_unit.dart';

/// Why a unit appears in a day's detail list.
enum CalendarDayUnitReason { due, activity, both, undated }

/// Month-grid marker flags for a single day.
class CalendarDayFlags {
  const CalendarDayFlags({
    this.hasDue = false,
    this.hasActivity = false,
    this.hasCompleted = false,
  });

  final bool hasDue;
  final bool hasActivity;
  final bool hasCompleted;

  bool get isEmpty => !hasDue && !hasActivity && !hasCompleted;

  /// True when both due and study activity are present (「两者」).
  bool get hasBoth => hasDue && hasActivity;
}

/// Units + reasons + average completion for a selected day.
class CalendarDaySlice {
  const CalendarDaySlice({
    required this.units,
    required this.reasons,
    required this.completionRate,
  });

  const CalendarDaySlice.empty()
      : units = const <LearningUnit>[],
        reasons = const <String, CalendarDayUnitReason>{},
        completionRate = 0;

  final List<LearningUnit> units;
  final Map<String, CalendarDayUnitReason> reasons;
  final double completionRate; // 0..1 average progress of listed units

  CalendarDayUnitReason reasonFor(LearningUnit u) =>
      reasons[u.id] ?? CalendarDayUnitReason.due;
}

/// Indexes due / study-activity / completed markers for one visible month.
class CalendarBoardIndex {
  CalendarBoardIndex._({
    required this.month,
    required this.flagsByDay,
    required this.dueByDay,
    required this.activityByDay,
  });

  final DateTime month;
  final Map<int, CalendarDayFlags> flagsByDay;
  final Map<int, List<LearningUnit>> dueByDay;
  final Map<int, List<LearningUnit>> activityByDay;

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool inMonth(DateTime d, DateTime month) =>
      d.year == month.year && d.month == month.month;

  /// Study activity: progress-touching updates (updatedAt) or completedAt.
  /// Pure create-on-same-day without progress is not treated as study.
  static bool hasStudyActivityOn(LearningUnit unit, DateTime day) {
    final completedAt = unit.completedAt;
    if (completedAt != null && isSameDay(completedAt, day)) return true;

    if (!isSameDay(unit.updatedAt, day)) return false;

    final createdSameDay = isSameDay(unit.createdAt, day);
    if (!createdSameDay) return true;

    final progress = unit.progress;
    if (progress.percent > 0) return true;
    if (progress.watchedMsByMedia.values.any((ms) => ms > 0)) return true;
    if (progress.completedMediaIds.isNotEmpty) return true;
    if (unit.status == LearningUnitStatus.completed) return true;
    return false;
  }

  factory CalendarBoardIndex.build(
    List<LearningUnit> units,
    DateTime month,
  ) {
    final dueByDay = <int, List<LearningUnit>>{};
    final activityByDay = <int, List<LearningUnit>>{};
    final flagsByDay = <int, CalendarDayFlags>{};

    void mergeFlags(int day, {CalendarDayFlags Function(CalendarDayFlags)? update}) {
      final prev = flagsByDay[day] ?? const CalendarDayFlags();
      flagsByDay[day] = update == null ? prev : update(prev);
    }

    for (final unit in units) {
      final due = unit.schedule.dueDate;
      if (due != null && inMonth(due, month)) {
        dueByDay.putIfAbsent(due.day, () => <LearningUnit>[]).add(unit);
        mergeFlags(
          due.day,
          update: (f) => CalendarDayFlags(
            hasDue: true,
            hasActivity: f.hasActivity,
            hasCompleted: f.hasCompleted ||
                unit.status == LearningUnitStatus.completed,
          ),
        );
      }

      // Scan possible activity days within month: updatedAt / completedAt.
      final candidates = <DateTime>{
        DateTime(
          unit.updatedAt.year,
          unit.updatedAt.month,
          unit.updatedAt.day,
        ),
        if (unit.completedAt != null)
          DateTime(
            unit.completedAt!.year,
            unit.completedAt!.month,
            unit.completedAt!.day,
          ),
      };
      for (final day in candidates) {
        if (!inMonth(day, month)) continue;
        if (!hasStudyActivityOn(unit, day)) continue;
        activityByDay.putIfAbsent(day.day, () => <LearningUnit>[]).add(unit);
        mergeFlags(
          day.day,
          update: (f) => CalendarDayFlags(
            hasDue: f.hasDue,
            hasActivity: true,
            hasCompleted: f.hasCompleted ||
                unit.status == LearningUnitStatus.completed ||
                (unit.completedAt != null && isSameDay(unit.completedAt!, day)),
          ),
        );
      }
    }

    return CalendarBoardIndex._(
      month: month,
      flagsByDay: flagsByDay,
      dueByDay: dueByDay,
      activityByDay: activityByDay,
    );
  }

  CalendarDayFlags flagsFor(int day) =>
      flagsByDay[day] ?? const CalendarDayFlags();

  CalendarDaySlice sliceFor(DateTime selected) {
    if (!inMonth(selected, month)) return const CalendarDaySlice.empty();

    final due = dueByDay[selected.day] ?? const <LearningUnit>[];
    final activity = activityByDay[selected.day] ?? const <LearningUnit>[];
    final byId = <String, LearningUnit>{};
    final reasons = <String, CalendarDayUnitReason>{};

    for (final u in due) {
      byId[u.id] = u;
      reasons[u.id] = CalendarDayUnitReason.due;
    }
    for (final u in activity) {
      byId[u.id] = u;
      reasons[u.id] = reasons.containsKey(u.id)
          ? CalendarDayUnitReason.both
          : CalendarDayUnitReason.activity;
    }

    final list = byId.values.toList()
      ..sort((a, b) {
        // Incomplete first, then by title.
        final ac = a.status == LearningUnitStatus.completed ? 1 : 0;
        final bc = b.status == LearningUnitStatus.completed ? 1 : 0;
        if (ac != bc) return ac.compareTo(bc);
        return a.title.compareTo(b.title);
      });

    var rate = 0.0;
    if (list.isNotEmpty) {
      rate = list
              .map((u) => u.progress.percent.clamp(0.0, 1.0))
              .fold<double>(0, (a, b) => a + b) /
          list.length;
    }

    return CalendarDaySlice(units: list, reasons: reasons, completionRate: rate);
  }
}

/// Chinese labels aligned with the month-grid legend.
String calendarDayReasonLabel(CalendarDayUnitReason reason) {
  switch (reason) {
    case CalendarDayUnitReason.due:
      return '有截止';
    case CalendarDayUnitReason.activity:
      return '有学习';
    case CalendarDayUnitReason.both:
      return '截止+学习';
    case CalendarDayUnitReason.undated:
      return '未设截止';
  }
}
