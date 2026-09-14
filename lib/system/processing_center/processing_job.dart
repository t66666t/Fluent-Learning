import 'package:fluent_learning/system/processing_center/processing_job_type.dart';

/// Coarse queue phase shown in Processing Center.
enum ProcessingJobPhase {
  queued,
  running,
  success,
  failed,
}

/// Immutable view of one processing-center job row.
class ProcessingJobView {
  const ProcessingJobView({
    required this.id,
    required this.type,
    required this.phase,
    required this.title,
    required this.createdAt,
    this.mediaKey,
    this.progress = 0.0,
    this.message = '',
  });

  final String id;
  final ProcessingJobType type;
  final ProcessingJobPhase phase;
  final String title;
  final int createdAt;
  final String? mediaKey;
  final double progress;
  final String message;

  ProcessingJobView copyWith({
    String? id,
    ProcessingJobType? type,
    ProcessingJobPhase? phase,
    String? title,
    int? createdAt,
    String? mediaKey,
    double? progress,
    String? message,
  }) {
    return ProcessingJobView(
      id: id ?? this.id,
      type: type ?? this.type,
      phase: phase ?? this.phase,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      mediaKey: mediaKey ?? this.mediaKey,
      progress: progress ?? this.progress,
      message: message ?? this.message,
    );
  }
}
