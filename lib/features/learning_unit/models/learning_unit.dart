import 'package:fluent_learning/domain/sync/sync_entity.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit_item_ref.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit_progress.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit_schedule.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit_status.dart';

export 'package:fluent_learning/features/learning_unit/models/learning_unit_item_ref.dart';
export 'package:fluent_learning/features/learning_unit/models/learning_unit_progress.dart';
export 'package:fluent_learning/features/learning_unit/models/learning_unit_schedule.dart';
export 'package:fluent_learning/features/learning_unit/models/learning_unit_status.dart';

/// A planned set of media/folders to learn through, bound to calendar.
class LearningUnit implements SyncEntity {
  @override
  final String id;
  final String title;
  final String? notes;
  final LearningUnitStatus status;
  final List<LearningUnitItemRef> itemRefs;
  final LearningUnitSchedule schedule;
  final LearningUnitProgress progress;
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final DateTime? completedAt;
  @override
  final DateTime? deletedAt;
  @override
  final int? revision;

  const LearningUnit({
    required this.id,
    required this.title,
    this.notes,
    this.status = LearningUnitStatus.planned,
    this.itemRefs = const <LearningUnitItemRef>[],
    this.schedule = const LearningUnitSchedule(),
    this.progress = const LearningUnitProgress(),
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.deletedAt,
    this.revision,
  });

  bool get isDeleted => deletedAt != null;

  bool get isIncomplete =>
      status != LearningUnitStatus.completed &&
      status != LearningUnitStatus.archived &&
      !isDeleted;

  LearningUnit copyWith({
    String? title,
    String? notes,
    LearningUnitStatus? status,
    List<LearningUnitItemRef>? itemRefs,
    LearningUnitSchedule? schedule,
    LearningUnitProgress? progress,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? deletedAt,
    int? revision,
    bool clearCompletedAt = false,
    bool clearDeletedAt = false,
    bool clearNotes = false,
    bool clearRevision = false,
  }) {
    return LearningUnit(
      id: id,
      title: title ?? this.title,
      notes: clearNotes ? null : (notes ?? this.notes),
      status: status ?? this.status,
      itemRefs: itemRefs ?? this.itemRefs,
      schedule: schedule ?? this.schedule,
      progress: progress ?? this.progress,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      revision: clearRevision ? null : (revision ?? this.revision),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      if (notes != null) 'notes': notes,
      'status': status.name,
      'itemRefs': itemRefs.map((e) => e.toJson()).toList(),
      'schedule': schedule.toJson(),
      'progress': progress.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      if (revision != null) 'revision': revision,
    };
  }

  @override
  Map<String, dynamic> toSyncJson() => toJson();

  factory LearningUnit.fromJson(Map<String, dynamic> json) {
    final refsRaw = json['itemRefs'];
    return LearningUnit(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      notes: json['notes'] as String?,
      status: LearningUnitStatus.fromName(json['status'] as String?),
      itemRefs: refsRaw is List
          ? refsRaw
              .whereType<Map>()
              .map(
                (e) => LearningUnitItemRef.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const <LearningUnitItemRef>[],
      schedule: LearningUnitSchedule.fromJson(
        json['schedule'] is Map
            ? Map<String, dynamic>.from(json['schedule'] as Map)
            : null,
      ),
      progress: LearningUnitProgress.fromJson(
        json['progress'] is Map
            ? Map<String, dynamic>.from(json['progress'] as Map)
            : null,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
      deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
      revision: (json['revision'] as num?)?.toInt(),
    );
  }
}
