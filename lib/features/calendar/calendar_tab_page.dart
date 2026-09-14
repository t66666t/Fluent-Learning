import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/features/calendar/calendar_board_index.dart';
import 'package:fluent_learning/features/learning_unit/data/learning_unit_repository.dart';
import 'package:fluent_learning/features/learning_unit/due_relative_label.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit.dart';
import 'package:fluent_learning/features/learning_unit/pages/learning_unit_detail_page.dart';
import 'package:fluent_learning/services/library_service.dart';

/// 「日历」Tab — month board with due / study-activity / completed markers.
class CalendarTabPage extends StatefulWidget {
  const CalendarTabPage({super.key});

  @override
  State<CalendarTabPage> createState() => _CalendarTabPageState();
}

class _CalendarTabPageState extends State<CalendarTabPage> {
  late DateTime _month; // first day of visible month
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDay = null;
    });
  }

  /// Open unit detail; restore selected day after pop (Phase 15).
  Future<void> _openUnit(String unitId) async {
    final keptDay = _selectedDay;
    final keptMonth = _month;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LearningUnitDetailPage(unitId: unitId),
        settings: RouteSettings(name: '/learning_unit/$unitId'),
      ),
    );
    if (!mounted) return;
    // Preserve calendar selection if anything reset it while detail was open.
    if (_selectedDay != keptDay || _month != keptMonth) {
      setState(() {
        _month = keptMonth;
        _selectedDay = keptDay;
      });
    }
  }

  /// 「开始学」: detail + autoContinue → PlaybackNavigation (home continue path).
  Future<void> _startLearning(LearningUnit unit) async {
    final keptDay = _selectedDay;
    final keptMonth = _month;
    final repo = context.read<LearningUnitRepository>();
    final library = context.read<LibraryService>();
    final nextId = repo.nextIncompleteMediaId(unit);
    final canContinue =
        nextId != null && library.getVideo(nextId) != null;

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LearningUnitDetailPage(
          unitId: unit.id,
          autoContinueLearning: canContinue,
        ),
        settings: RouteSettings(name: '/learning_unit/${unit.id}'),
      ),
    );
    if (!mounted) return;
    if (_selectedDay != keptDay || _month != keptMonth) {
      setState(() {
        _month = keptMonth;
        _selectedDay = keptDay;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('日历'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '上个月',
            onPressed: () => _shiftMonth(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Center(
            child: Text(
              '${_month.year}年${_month.month}月',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: '下个月',
            onPressed: () => _shiftMonth(1),
            icon: const Icon(Icons.chevron_right),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<LearningUnitRepository>(
        builder: (context, repo, _) {
          // Rebuilds whenever repository notifies (due/edit/progress).
          final board = CalendarBoardIndex.build(repo.units, _month);

          final selected = _selectedDay;
          final daySlice = selected == null
              ? const CalendarDaySlice.empty()
              : board.sliceFor(selected);

          final undated = repo.units
              .where((u) => u.schedule.dueDate == null && u.isIncomplete)
              .take(12)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              _MonthGrid(
                month: _month,
                selectedDay: _selectedDay,
                board: board,
                onSelect: (day) {
                  setState(() {
                    _selectedDay = day;
                  });
                },
              ),
              const SizedBox(height: 10),
              const _MarkerLegend(),
              const SizedBox(height: 16),
              _DayDetailHeader(
                selected: selected,
                slice: daySlice,
              ),
              const SizedBox(height: 8),
              if (daySlice.units.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                  child: Text(
                    '该日暂无截止或学习 · 去首页新建单元或设置截止',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                )
              else
                ...daySlice.units.map(
                  (u) => _CalendarUnitTile(
                    unit: u,
                    reason: daySlice.reasonFor(u),
                    onTap: () => _openUnit(u.id),
                    onStartLearning: u.isIncomplete
                        ? () => _startLearning(u)
                        : null,
                  ),
                ),
              if (undated.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  '未设截止日期',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                ...undated.map(
                  (u) => _CalendarUnitTile(
                    unit: u,
                    reason: CalendarDayUnitReason.undated,
                    onTap: () => _openUnit(u.id),
                    onStartLearning: () => _startLearning(u),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDay,
    required this.board,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime? selectedDay;
  final CalendarBoardIndex board;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // Mon=1
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = firstWeekday - 1;
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final today = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      child: Column(
        children: [
          Row(
            children: const [
              _Dow('一'),
              _Dow('二'),
              _Dow('三'),
              _Dow('四'),
              _Dow('五'),
              _Dow('六'),
              _Dow('日'),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final dayNum = index - leading + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox.shrink();
              }
              final date = DateTime(month.year, month.month, dayNum);
              final flags = board.flagsFor(dayNum);
              final isSelected = selectedDay != null &&
                  selectedDay!.year == date.year &&
                  selectedDay!.month == date.month &&
                  selectedDay!.day == date.day;
              final isToday = today.year == date.year &&
                  today.month == date.month &&
                  today.day == date.day;

              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSelect(date),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withValues(alpha: 0.35)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: Colors.lightBlueAccent, width: 1)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                      if (!flags.isEmpty) ...[
                        const SizedBox(height: 3),
                        _DayMarkers(flags: flags),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Distinct marker styles: due (amber diamond), activity (cyan circle),
/// completed (green check-dot). Combined due+activity = both markers.
class _DayMarkers extends StatelessWidget {
  const _DayMarkers({required this.flags});

  final CalendarDayFlags flags;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (flags.hasDue) {
      children.add(
        const _MarkerChip(
          color: Color(0xFFFFB74D), // amber — has due
          shape: _MarkerShape.diamond,
        ),
      );
    }
    if (flags.hasActivity) {
      children.add(
        const _MarkerChip(
          color: Color(0xFF4FC3F7), // cyan — study activity
          shape: _MarkerShape.circle,
        ),
      );
    }
    if (flags.hasCompleted) {
      children.add(
        const _MarkerChip(
          color: Color(0xFF69F0AE), // green — completed
          shape: _MarkerShape.square,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          children[i],
        ],
      ],
    );
  }
}

enum _MarkerShape { circle, diamond, square }

class _MarkerChip extends StatelessWidget {
  const _MarkerChip({required this.color, required this.shape});

  final Color color;
  final _MarkerShape shape;

  @override
  Widget build(BuildContext context) {
    switch (shape) {
      case _MarkerShape.circle:
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        );
      case _MarkerShape.square:
        return Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      case _MarkerShape.diamond:
        return Transform.rotate(
          angle: 0.785398, // 45°
          child: Container(
            width: 5,
            height: 5,
            color: color,
          ),
        );
    }
  }
}

class _MarkerLegend extends StatelessWidget {
  const _MarkerLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: const [
        _LegendItem(
          chip: _MarkerChip(
            color: Color(0xFFFFB74D),
            shape: _MarkerShape.diamond,
          ),
          label: '有截止',
        ),
        _LegendItem(
          chip: _MarkerChip(
            color: Color(0xFF4FC3F7),
            shape: _MarkerShape.circle,
          ),
          label: '有学习',
        ),
        _LegendItem(
          chip: _MarkerChip(
            color: Color(0xFF69F0AE),
            shape: _MarkerShape.square,
          ),
          label: '已完成',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.chip, required this.label});

  final Widget chip;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip,
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

class _DayDetailHeader extends StatelessWidget {
  const _DayDetailHeader({required this.selected, required this.slice});

  final DateTime? selected;
  final CalendarDaySlice slice;

  @override
  Widget build(BuildContext context) {
    if (selected == null) {
      return Text(
        '选择日期查看单元',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      );
    }

    final pct = (slice.completionRate * 100).clamp(0, 100).toStringAsFixed(0);
    final count = slice.units.length;
    final doneCount =
        slice.units.where((u) => u.status == LearningUnitStatus.completed).length;

    return Row(
      children: [
        Expanded(
          child: Text(
            '${selected!.month}/${selected!.day} 日详情',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (count > 0)
          Text(
            '完成率 $pct% · $doneCount/$count',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
      ],
    );
  }
}

class _Dow extends StatelessWidget {
  const _Dow(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
    );
  }
}

class _CalendarUnitTile extends StatelessWidget {
  const _CalendarUnitTile({
    required this.unit,
    required this.onTap,
    this.reason = CalendarDayUnitReason.due,
    this.onStartLearning,
  });

  final LearningUnit unit;
  final VoidCallback onTap;
  final CalendarDayUnitReason reason;
  final VoidCallback? onStartLearning;

  @override
  Widget build(BuildContext context) {
    final pct = (unit.progress.percent * 100).clamp(0, 100).toStringAsFixed(0);
    final relative = dueRelativeLabel(unit.schedule.dueDate);
    final reasonLabel = calendarDayReasonLabel(reason);
    final subtitleParts = <String>[
      unit.status.labelZh,
      '$pct%',
      reasonLabel,
      ?relative,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onTap: onTap,
          leading: _reasonIcon(reason, unit),
          title: Text(
            unit.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            subtitleParts.join(' · '),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          trailing: onStartLearning != null
              ? TextButton(
                  onPressed: onStartLearning,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.lightBlueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('开始学'),
                )
              : Icon(
                  unit.status == LearningUnitStatus.completed
                      ? Icons.check_circle
                      : Icons.chevron_right,
                  color: unit.status == LearningUnitStatus.completed
                      ? Colors.greenAccent
                      : Colors.white38,
                ),
        ),
      ),
    );
  }

  static Widget _reasonIcon(CalendarDayUnitReason reason, LearningUnit unit) {
    if (unit.status == LearningUnitStatus.completed) {
      return const Icon(Icons.check_box, color: Color(0xFF69F0AE), size: 22);
    }
    switch (reason) {
      case CalendarDayUnitReason.due:
        return const Icon(Icons.event, color: Color(0xFFFFB74D), size: 22);
      case CalendarDayUnitReason.activity:
        return const Icon(Icons.school, color: Color(0xFF4FC3F7), size: 22);
      case CalendarDayUnitReason.both:
        return const Icon(Icons.event_available,
            color: Color(0xFFFFB74D), size: 22);
      case CalendarDayUnitReason.undated:
        return const Icon(Icons.schedule, color: Colors.white38, size: 22);
    }
  }
}
