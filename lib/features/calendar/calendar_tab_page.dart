import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/features/learning_unit/data/learning_unit_repository.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit.dart';
import 'package:fluent_learning/features/learning_unit/pages/learning_unit_detail_page.dart';

/// 「日历」Tab — month board of units by dueDate + completion status.
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

  void _openUnit(String unitId) {
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
          final dueByDay = <int, List<LearningUnit>>{};
          for (final unit in repo.units) {
            final due = unit.schedule.dueDate;
            if (due == null) continue;
            if (due.year != _month.year || due.month != _month.month) continue;
            dueByDay.putIfAbsent(due.day, () => <LearningUnit>[]).add(unit);
          }

          final selected = _selectedDay;
          final dayUnits = selected == null
              ? const <LearningUnit>[]
              : (selected.year == _month.year && selected.month == _month.month
                  ? (dueByDay[selected.day] ?? const <LearningUnit>[])
                  : const <LearningUnit>[]);

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
                dueByDay: dueByDay,
                onSelect: (day) {
                  setState(() {
                    _selectedDay = day;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(
                selected == null
                    ? '选择日期查看单元'
                    : '${selected.month}/${selected.day} 截止',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              if (dayUnits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    '该日无截止单元',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              else
                ...dayUnits.map(
                  (u) => _CalendarUnitTile(
                    unit: u,
                    onTap: () => _openUnit(u.id),
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
                    onTap: () => _openUnit(u.id),
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

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDay,
    required this.dueByDay,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime? selectedDay;
  final Map<int, List<LearningUnit>> dueByDay;
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
              final units = dueByDay[dayNum] ?? const <LearningUnit>[];
              final isSelected = selectedDay != null &&
                  selectedDay!.year == date.year &&
                  selectedDay!.month == date.month &&
                  selectedDay!.day == date.day;
              final isToday = today.year == date.year &&
                  today.month == date.month &&
                  today.day == date.day;
              final allDone = units.isNotEmpty &&
                  units.every((u) => u.status == LearningUnitStatus.completed);

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
                      if (units.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: allDone
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                          ),
                        ),
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
  const _CalendarUnitTile({required this.unit, required this.onTap});

  final LearningUnit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = (unit.progress.percent * 100).clamp(0, 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onTap: onTap,
          title: Text(
            unit.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${unit.status.labelZh} · $pct%',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          trailing: Icon(
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
}
