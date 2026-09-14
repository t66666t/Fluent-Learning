import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/app/responsive.dart';
import 'package:fluent_learning/core/theme_tokens.dart';
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
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('日历'),
        backgroundColor: AppColors.elevated,
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

          final metrics = _CalendarMetrics.of(context);
          return ListView(
            padding: metrics.listPadding,
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
              SizedBox(height: metrics.legendGap),
              const _MarkerLegend(),
              SizedBox(height: metrics.detailGap),
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: metrics.detailMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DayDetailHeader(
                        selected: selected,
                        slice: daySlice,
                      ),
                      SizedBox(height: metrics.itemGap),
                      if (daySlice.units.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: metrics.emptyVertical,
                            horizontal: 12,
                          ),
                          child: const Text(
                            '该日暂无截止或学习 · 去首页新建单元或设置截止',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        ...daySlice.units.map(
                          (u) => _CalendarUnitTile(
                            unit: u,
                            reason: daySlice.reasonFor(u),
                            dense: context.isCompact,
                            onTap: () => _openUnit(u.id),
                            onStartLearning: u.isIncomplete
                                ? () => _startLearning(u)
                                : null,
                          ),
                        ),
                      if (undated.isNotEmpty) ...[
                        SizedBox(height: metrics.sectionGap),
                        Text(
                          '未设截止日期',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                        ),
                        SizedBox(height: metrics.itemGap),
                        ...undated.map(
                          (u) => _CalendarUnitTile(
                            unit: u,
                            reason: CalendarDayUnitReason.undated,
                            dense: context.isCompact,
                            onTap: () => _openUnit(u.id),
                            onStartLearning: () => _startLearning(u),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
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
        color: AppColors.elevated,
        borderRadius: AppRadii.borderMd,
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
                borderRadius: AppRadii.borderSm,
                onTap: () => onSelect(date),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.28)
                        : Colors.transparent,
                    borderRadius: AppRadii.borderSm,
                    border: isToday
                        ? Border.all(color: AppColors.primary, width: 1)
                        : (isSelected
                            ? Border.all(
                                color: AppColors.primary.withValues(alpha: 0.55),
                              )
                            : null),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant,
                          fontWeight:
                              isToday || isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
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
          color: AppColors.warning, // amber — has due
          shape: _MarkerShape.diamond,
        ),
      );
    }
    if (flags.hasActivity) {
      children.add(
        const _MarkerChip(
          color: AppColors.primary, // cyan — study activity
          shape: _MarkerShape.circle,
        ),
      );
    }
    if (flags.hasCompleted) {
      children.add(
        const _MarkerChip(
          color: AppColors.success, // green — completed
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
            color: AppColors.warning,
            shape: _MarkerShape.diamond,
          ),
          label: '有截止',
        ),
        _LegendItem(
          chip: _MarkerChip(
            color: AppColors.primary,
            shape: _MarkerShape.circle,
          ),
          label: '有学习',
        ),
        _LegendItem(
          chip: _MarkerChip(
            color: AppColors.success,
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
          style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
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
              color: AppColors.onSurface,
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
            style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
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
        style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
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
    this.dense = false,
  });

  final LearningUnit unit;
  final VoidCallback onTap;
  final CalendarDayUnitReason reason;
  final VoidCallback? onStartLearning;
  final bool dense;

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
      padding: EdgeInsets.only(bottom: dense ? 6 : 8),
      child: Material(
        color: AppColors.elevated,
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: AppRadii.borderMd,
        child: ListTile(
          dense: dense,
          contentPadding: EdgeInsets.symmetric(
            horizontal: dense ? 10 : 14,
            vertical: dense ? 0 : 2,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
          onTap: onTap,
          leading: _reasonIcon(reason, unit),
          title: Text(
            unit.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.onSurface),
          ),
          subtitle: Text(
            subtitleParts.join(' · '),
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          trailing: onStartLearning != null
              ? TextButton(
                  onPressed: onStartLearning,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
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
                      ? AppColors.success
                      : AppColors.onSurfaceVariant,
                ),
        ),
      ),
    );
  }

  static Widget _reasonIcon(CalendarDayUnitReason reason, LearningUnit unit) {
    if (unit.status == LearningUnitStatus.completed) {
      return const Icon(Icons.check_box, color: AppColors.success, size: 22);
    }
    switch (reason) {
      case CalendarDayUnitReason.due:
        return const Icon(Icons.event, color: AppColors.warning, size: 22);
      case CalendarDayUnitReason.activity:
        return const Icon(Icons.school, color: AppColors.primary, size: 22);
      case CalendarDayUnitReason.both:
        return const Icon(
          Icons.event_available,
          color: AppColors.warning,
          size: 22,
        );
      case CalendarDayUnitReason.undated:
        return const Icon(
          Icons.schedule,
          color: AppColors.onSurfaceVariant,
          size: 22,
        );
    }
  }
}

/// Responsive calendar density — tighter day detail on phone, wider on desktop.
class _CalendarMetrics {
  const _CalendarMetrics({
    required this.listPadding,
    required this.legendGap,
    required this.detailGap,
    required this.itemGap,
    required this.sectionGap,
    required this.emptyVertical,
    required this.detailMaxWidth,
  });

  final EdgeInsets listPadding;
  final double legendGap;
  final double detailGap;
  final double itemGap;
  final double sectionGap;
  final double emptyVertical;
  final double detailMaxWidth;

  static _CalendarMetrics of(BuildContext context) {
    if (context.isCompact) {
      return const _CalendarMetrics(
        listPadding: EdgeInsets.fromLTRB(10, 6, 10, 20),
        legendGap: 8,
        detailGap: 12,
        itemGap: 6,
        sectionGap: 16,
        emptyVertical: 16,
        detailMaxWidth: double.infinity,
      );
    }
    if (context.isExpanded) {
      return const _CalendarMetrics(
        listPadding: EdgeInsets.fromLTRB(24, 12, 24, 32),
        legendGap: 12,
        detailGap: 20,
        itemGap: 10,
        sectionGap: 24,
        emptyVertical: 24,
        detailMaxWidth: 720,
      );
    }
    return const _CalendarMetrics(
      listPadding: EdgeInsets.fromLTRB(14, 8, 14, 24),
      legendGap: 10,
      detailGap: 16,
      itemGap: 8,
      sectionGap: 20,
      emptyVertical: 20,
      detailMaxWidth: 560,
    );
  }
}
