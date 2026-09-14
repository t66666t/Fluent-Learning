/// Lifecycle status for a [LearningUnit].
enum LearningUnitStatus {
  planned,
  active,
  paused,
  completed,
  archived;

  static LearningUnitStatus fromName(String? raw) {
    if (raw == null || raw.isEmpty) return LearningUnitStatus.planned;
    for (final value in LearningUnitStatus.values) {
      if (value.name == raw) return value;
    }
    return LearningUnitStatus.planned;
  }

  String get labelZh {
    switch (this) {
      case LearningUnitStatus.planned:
        return '计划中';
      case LearningUnitStatus.active:
        return '进行中';
      case LearningUnitStatus.paused:
        return '已暂停';
      case LearningUnitStatus.completed:
        return '已完成';
      case LearningUnitStatus.archived:
        return '已归档';
    }
  }
}
