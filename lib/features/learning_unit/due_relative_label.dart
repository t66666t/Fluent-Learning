/// Relative due-date copy for home / calendar cards (今天 / 逾期 / 还有 N 天).
///
/// Compares calendar days in local time; returns null when [due] is null.
String? dueRelativeLabel(DateTime? due, {DateTime? now}) {
  if (due == null) return null;
  final clock = now ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  final dueDay = DateTime(due.year, due.month, due.day);
  final days = dueDay.difference(today).inDays;
  if (days < 0) return '逾期';
  if (days == 0) return '今天';
  return '还有 $days 天';
}
