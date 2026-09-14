import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/features/calendar/calendar_board_index.dart';
import 'package:fluent_learning/features/calendar/calendar_tab_page.dart';
import 'package:fluent_learning/features/learning_unit/data/learning_unit_repository.dart';
import 'package:fluent_learning/features/learning_unit/due_relative_label.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit.dart';
import 'package:fluent_learning/services/library_service.dart';

LearningUnit _unit({
  required String id,
  required String title,
  LearningUnitStatus status = LearningUnitStatus.active,
  DateTime? due,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? completedAt,
  double percent = 0,
  Map<String, int> watched = const {},
  List<String> completedMediaIds = const [],
  List<LearningUnitItemRef> itemRefs = const [],
}) {
  final now = DateTime(2026, 9, 14, 12);
  return LearningUnit(
    id: id,
    title: title,
    status: status,
    itemRefs: itemRefs,
    schedule: LearningUnitSchedule(dueDate: due),
    progress: LearningUnitProgress(
      percent: percent,
      watchedMsByMedia: watched,
      completedMediaIds: completedMediaIds,
    ),
    createdAt: createdAt ?? now.subtract(const Duration(days: 10)),
    updatedAt: updatedAt ?? now.subtract(const Duration(days: 5)),
    completedAt: completedAt,
  );
}

Future<void> _pumpCalendar(
  WidgetTester tester,
  LearningUnitRepository repo,
) async {
  // Tall surface so month grid + day detail are both built (ListView lazy).
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LearningUnitRepository>.value(value: repo),
        ChangeNotifierProvider<LibraryService>.value(value: LibraryService()),
      ],
      child: const MaterialApp(home: CalendarTabPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('dueRelativeLabel', () {
    final now = DateTime(2026, 9, 14, 15, 30);

    test('null due → null', () {
      expect(dueRelativeLabel(null, now: now), isNull);
    });

    test('today / overdue / remaining days', () {
      expect(
        dueRelativeLabel(DateTime(2026, 9, 14, 23, 59), now: now),
        '今天',
      );
      expect(
        dueRelativeLabel(DateTime(2026, 9, 13, 8), now: now),
        '逾期',
      );
      expect(
        dueRelativeLabel(DateTime(2026, 9, 17, 23, 59), now: now),
        '还有 3 天',
      );
      expect(
        dueRelativeLabel(DateTime(2026, 9, 15), now: now),
        '还有 1 天',
      );
    });
  });

  group('CalendarBoardIndex markers', () {
    final month = DateTime(2026, 9);

    test('due / activity / completed / both flags and day-detail reasons', () {
      final dueOnly = _unit(
        id: 'due',
        title: 'DueOnly',
        due: DateTime(2026, 9, 10, 23, 59),
        updatedAt: DateTime(2026, 8, 1),
      );
      final activityOnly = _unit(
        id: 'act',
        title: 'ActOnly',
        percent: 0.3,
        updatedAt: DateTime(2026, 9, 12, 18),
        createdAt: DateTime(2026, 9, 1),
      );
      final both = _unit(
        id: 'both',
        title: 'Both',
        due: DateTime(2026, 9, 14, 23, 59),
        percent: 0.5,
        updatedAt: DateTime(2026, 9, 14, 10),
        createdAt: DateTime(2026, 9, 1),
      );
      final completed = _unit(
        id: 'done',
        title: 'Done',
        status: LearningUnitStatus.completed,
        due: DateTime(2026, 9, 20, 23, 59),
        percent: 1,
        completedAt: DateTime(2026, 9, 15, 9),
        updatedAt: DateTime(2026, 9, 15, 9),
        createdAt: DateTime(2026, 9, 1),
      );

      final board = CalendarBoardIndex.build(
        [dueOnly, activityOnly, both, completed],
        month,
      );

      expect(board.flagsFor(10).hasDue, isTrue);
      expect(board.flagsFor(10).hasActivity, isFalse);
      expect(board.flagsFor(10).hasCompleted, isFalse);

      expect(board.flagsFor(12).hasDue, isFalse);
      expect(board.flagsFor(12).hasActivity, isTrue);

      final bothFlags = board.flagsFor(14);
      expect(bothFlags.hasDue, isTrue);
      expect(bothFlags.hasActivity, isTrue);
      expect(bothFlags.hasBoth, isTrue);

      final doneFlags = board.flagsFor(15);
      expect(doneFlags.hasActivity, isTrue);
      expect(doneFlags.hasCompleted, isTrue);

      // Due day also marks completed when unit status is completed.
      expect(board.flagsFor(20).hasDue, isTrue);
      expect(board.flagsFor(20).hasCompleted, isTrue);

      final slice14 = board.sliceFor(DateTime(2026, 9, 14));
      expect(slice14.reasonFor(both), CalendarDayUnitReason.both);
      expect(calendarDayReasonLabel(CalendarDayUnitReason.due), '有截止');
      expect(calendarDayReasonLabel(CalendarDayUnitReason.activity), '有学习');
      expect(calendarDayReasonLabel(CalendarDayUnitReason.both), '截止+学习');
    });

    test('create-only same day without progress is not study activity', () {
      final created = _unit(
        id: 'new',
        title: 'New',
        createdAt: DateTime(2026, 9, 8, 9),
        updatedAt: DateTime(2026, 9, 8, 9),
        percent: 0,
      );
      final board = CalendarBoardIndex.build([created], month);
      expect(board.flagsFor(8).isEmpty, isTrue);
    });
  });

  group('CalendarTabPage UI', () {
    testWidgets('empty day shows one-line Home guide', (tester) async {
      final repo = LearningUnitRepository()..persistToDisk = false;
      await _pumpCalendar(tester, repo);

      expect(find.textContaining('去首页新建单元或设置截止'), findsOneWidget);
      expect(find.text('有截止'), findsOneWidget);
      expect(find.text('有学习'), findsOneWidget);
      expect(find.text('已完成'), findsOneWidget);
    });

    testWidgets('incomplete day tile shows 开始学 and relative due',
        (tester) async {
      final repo = LearningUnitRepository()..persistToDisk = false;
      final now = DateTime.now();
      final due = DateTime(now.year, now.month, now.day, 23, 59);
      await repo.create(
        title: 'Phase17 Unit',
        itemRefs: const [LearningUnitItemRef.media('m1')],
        schedule: LearningUnitSchedule(dueDate: due),
      );

      await _pumpCalendar(tester, repo);

      expect(find.text('Phase17 Unit'), findsOneWidget);
      expect(find.text('开始学'), findsOneWidget);
      expect(find.textContaining('今天'), findsWidgets);
      expect(find.textContaining('有截止'), findsWidgets);
    });
  });
}
