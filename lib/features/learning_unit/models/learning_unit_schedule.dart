/// Optional schedule / plan fields for a learning unit.
class LearningUnitSchedule {
  final DateTime? startDate;
  final DateTime? dueDate;
  final int? targetMinutesPerDay;

  /// Bitmask: bit 0 = Monday … bit 6 = Sunday. Null = every day.
  final int? weekdayMask;

  const LearningUnitSchedule({
    this.startDate,
    this.dueDate,
    this.targetMinutesPerDay,
    this.weekdayMask,
  });

  LearningUnitSchedule copyWith({
    DateTime? startDate,
    DateTime? dueDate,
    int? targetMinutesPerDay,
    int? weekdayMask,
    bool clearDueDate = false,
    bool clearStartDate = false,
  }) {
    return LearningUnitSchedule(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      targetMinutesPerDay: targetMinutesPerDay ?? this.targetMinutesPerDay,
      weekdayMask: weekdayMask ?? this.weekdayMask,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      if (targetMinutesPerDay != null)
        'targetMinutesPerDay': targetMinutesPerDay,
      if (weekdayMask != null) 'weekdayMask': weekdayMask,
    };
  }

  factory LearningUnitSchedule.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LearningUnitSchedule();
    return LearningUnitSchedule(
      startDate: _parseDate(json['startDate']),
      dueDate: _parseDate(json['dueDate']),
      targetMinutesPerDay: json['targetMinutesPerDay'] as int?,
      weekdayMask: json['weekdayMask'] as int?,
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}
