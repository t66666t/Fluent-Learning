import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'package:fluent_learning/models/batch_subtitle_task_view.dart';
import 'package:fluent_learning/models/transcription_status.dart';
import 'package:fluent_learning/services/library_service.dart';
import 'package:fluent_learning/services/settings_service.dart';
import 'package:fluent_learning/services/transcription_manager.dart';
import 'package:fluent_learning/system/processing_center/processing_job.dart';
import 'package:fluent_learning/system/model_center/model_center.dart';
import 'package:fluent_learning/system/processing_center/processing_job_type.dart';

/// System Processing Center — thin queue facade over existing managers.
///
/// MVP maps [ProcessingJobType.transcription] to [TranscriptionManager] and
/// mirrors its queue into a stable job list (pc_* ids when enqueued here).
class ProcessingCenter extends ChangeNotifier {
  ProcessingCenter({
    required TranscriptionManager transcriptionManager,
    required LibraryService libraryService,
    required SettingsService settingsService,
    ModelCenter? modelCenter,
  })  : _transcriptionManager = transcriptionManager,
        _libraryService = libraryService,
        _settingsService = settingsService,
        _modelCenter = modelCenter {
    _transcriptionManager.addListener(_onTranscriptionChanged);
    _syncFromTranscriptionManager();
  }

  final TranscriptionManager _transcriptionManager;
  final LibraryService _libraryService;
  final SettingsService _settingsService;
  final ModelCenter? _modelCenter;

  int _jobSeq = 0;

  /// mediaKey → facade job id (stable across TM status updates).
  final Map<String, String> _jobIdByMediaKey = <String, String>{};

  /// Ordered job rows for UI (newest-relevant: running/queued first).
  List<ProcessingJobView> _jobs = const <ProcessingJobView>[];

  List<ProcessingJobView> get jobs =>
      List<ProcessingJobView>.unmodifiable(_jobs);

  int get queuedCount =>
      _jobs.where((j) => j.phase == ProcessingJobPhase.queued).length;

  int get runningCount =>
      _jobs.where((j) => j.phase == ProcessingJobPhase.running).length;

  int get successCount =>
      _jobs.where((j) => j.phase == ProcessingJobPhase.success).length;

  int get failedCount =>
      _jobs.where((j) => j.phase == ProcessingJobPhase.failed).length;

  @override
  void dispose() {
    _transcriptionManager.removeListener(_onTranscriptionChanged);
    super.dispose();
  }

  void _onTranscriptionChanged() {
    _syncFromTranscriptionManager();
  }

  /// Enqueue a processing job. Returns a local job id string.
  ///
  /// For transcription, each [mediaIds] entry is resolved via [LibraryService].
  /// Path-only callers may pass `params['videoPath']` (+ optional `videoId`).
  /// The returned id is immediately present in [jobs] (queued).
  Future<String> enqueueProcessingJob({
    required ProcessingJobType type,
    required List<String> mediaIds,
    Map<String, dynamic>? params,
  }) async {
    final jobId = 'pc_${DateTime.now().millisecondsSinceEpoch}_${++_jobSeq}';

    switch (type) {
      case ProcessingJobType.transcription:
        await _enqueueTranscription(
          jobId: jobId,
          mediaIds: mediaIds,
          params: params,
        );
        break;
      case ProcessingJobType.translation:
      case ProcessingJobType.ocr:
      case ProcessingJobType.compose:
      case ProcessingJobType.custom:
        throw UnsupportedError(
          'ProcessingJobType.${type.name} 尚未接入处理中心门面',
        );
    }

    notifyListeners();
    return jobId;
  }

  Future<void> _enqueueTranscription({
    required String jobId,
    required List<String> mediaIds,
    Map<String, dynamic>? params,
  }) async {
    final autoStart = params?['autoStart'] as bool? ?? true;
    final autoCache =
        params?['autoCache'] as bool? ?? _settingsService.autoCacheSubtitles;

    // Prefer Model Center active model for the next job (no hard-coded ASR).
    final active = _modelCenter?.resolve(ModelKind.transcription);
    if (_modelCenter != null && active == null) {
      throw StateError('模型中心未配置可用转录模型');
    }
    final requestedId = params?['modelId'];
    final modelId = active?.id ??
        (requestedId is String && requestedId.trim().isNotEmpty
            ? requestedId.trim()
            : ModelCenter.bcutAsrId);
    if (active != null &&
        requestedId is String &&
        requestedId.trim().isNotEmpty &&
        requestedId.trim() != active.id) {
      debugPrint(
        'ProcessingCenter: params.modelId=$requestedId → using active '
        '${active.id} (${active.displayName})',
      );
    }
    debugPrint(
      'ProcessingCenter: transcription job via model $modelId'
      '${active != null ? ' (${active.displayName})' : ''}',
    );

    final targets = <_TranscriptionTarget>[];

    final pathParam = params?['videoPath'];
    if (pathParam is String && pathParam.trim().isNotEmpty) {
      final idParam = params?['videoId'];
      targets.add(
        _TranscriptionTarget(
          path: pathParam.trim(),
          videoId: idParam is String && idParam.trim().isNotEmpty
              ? idParam.trim()
              : (mediaIds.isNotEmpty ? mediaIds.first : null),
        ),
      );
    }

    for (final id in mediaIds) {
      final trimmed = id.trim();
      if (trimmed.isEmpty) continue;
      if (targets.any((t) => t.videoId == trimmed)) continue;
      final video = _libraryService.getVideo(trimmed);
      if (video == null) {
        debugPrint('ProcessingCenter: mediaId not found: $trimmed');
        continue;
      }
      targets.add(_TranscriptionTarget(path: video.path, videoId: video.id));
    }

    if (targets.isEmpty) {
      throw ArgumentError(
        'enqueueProcessingJob(transcription): 需要 mediaIds 或 params.videoPath',
      );
    }

    // Register rows before engine enqueue so the player-returned id is visible
    // in Processing Center immediately (same id for single-target enqueue).
    for (var i = 0; i < targets.length; i++) {
      final target = targets[i];
      final mediaKey = mediaKeyFor(target.path, videoId: target.videoId);
      final rowId = targets.length == 1 ? jobId : '${jobId}_$i';
      _jobIdByMediaKey[mediaKey] = rowId;
    }
    _syncFromTranscriptionManager(
      pendingTargets: targets,
      pendingJobId: jobId,
    );

    for (final target in targets) {
      await _transcriptionManager.startTranscription(
        target.path,
        videoId: target.videoId,
        libraryService: _libraryService,
        autoCache: autoCache,
        autoStart: autoStart,
      );
    }
  }

  /// Public helper matching TranscriptionManager media-key rules.
  static String mediaKeyFor(String videoPath, {String? videoId}) {
    final trimmedId = videoId?.trim();
    if (trimmedId != null && trimmedId.isNotEmpty) {
      return 'id:$trimmedId';
    }
    final normalizedPath = p.normalize(videoPath);
    final safePath =
        Platform.isWindows ? normalizedPath.toLowerCase() : normalizedPath;
    return 'path:$safePath';
  }

  void _syncFromTranscriptionManager({
    List<_TranscriptionTarget>? pendingTargets,
    String? pendingJobId,
  }) {
    final snapshot = _transcriptionManager.getQueueSnapshot();
    final byMediaKey = <String, BatchSubtitleTaskView>{};
    for (final task in snapshot) {
      byMediaKey[task.mediaKey] = task;
    }

    // Ensure pending enqueues appear even before TM notifies.
    if (pendingTargets != null && pendingJobId != null) {
      for (var i = 0; i < pendingTargets.length; i++) {
        final t = pendingTargets[i];
        final key = mediaKeyFor(t.path, videoId: t.videoId);
        if (byMediaKey.containsKey(key)) continue;
        final title = () {
          final id = t.videoId?.trim();
          if (id != null && id.isNotEmpty) {
            final v = _libraryService.getVideo(id);
            if (v != null && v.title.trim().isNotEmpty) return v.title;
          }
          return p.basename(t.path);
        }();
        byMediaKey[key] = BatchSubtitleTaskView(
          mediaKey: key,
          videoPath: t.path,
          videoId: t.videoId,
          videoName: title,
          videoDuration: '',
          isExternal: false,
          status: TranscriptionStatus.idle,
          progress: 0.0,
          statusMessage: '已加入处理中心队列',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          isStarted: true,
        );
        final rowId =
            pendingTargets.length == 1 ? pendingJobId : '${pendingJobId}_$i';
        _jobIdByMediaKey.putIfAbsent(key, () => rowId);
      }
    }

    // Drop stale id mappings for mediaKeys no longer in TM (+ pending).
    _jobIdByMediaKey
        .removeWhere((key, _) => !byMediaKey.containsKey(key));

    final next = <ProcessingJobView>[];
    for (final task in byMediaKey.values) {
      final id = _jobIdByMediaKey.putIfAbsent(
        task.mediaKey,
        () => 'tm_${task.mediaKey}',
      );
      next.add(
        ProcessingJobView(
          id: id,
          type: ProcessingJobType.transcription,
          phase: _phaseFor(task),
          title: task.videoName,
          createdAt: task.createdAt,
          mediaKey: task.mediaKey,
          progress: task.progress,
          message: task.statusMessage,
        ),
      );
    }

    next.sort((a, b) {
      final phaseOrder = _phaseSortKey(a.phase) - _phaseSortKey(b.phase);
      if (phaseOrder != 0) return phaseOrder;
      return b.createdAt.compareTo(a.createdAt);
    });

    _jobs = next;
    notifyListeners();
  }

  static int _phaseSortKey(ProcessingJobPhase phase) {
    switch (phase) {
      case ProcessingJobPhase.running:
        return 0;
      case ProcessingJobPhase.queued:
        return 1;
      case ProcessingJobPhase.failed:
        return 2;
      case ProcessingJobPhase.success:
        return 3;
    }
  }

  static ProcessingJobPhase _phaseFor(BatchSubtitleTaskView task) {
    switch (task.status) {
      case TranscriptionStatus.completed:
        return ProcessingJobPhase.success;
      case TranscriptionStatus.error:
        return ProcessingJobPhase.failed;
      case TranscriptionStatus.idle:
        return ProcessingJobPhase.queued;
      case TranscriptionStatus.downloading:
      case TranscriptionStatus.extracting:
      case TranscriptionStatus.uploading:
      case TranscriptionStatus.transcribing:
      case TranscriptionStatus.embedding:
        return ProcessingJobPhase.running;
    }
  }
}

class _TranscriptionTarget {
  const _TranscriptionTarget({required this.path, this.videoId});

  final String path;
  final String? videoId;
}

/// Top-level facade matching the Phase 3 API sketch.
///
/// Prefer `context.read<ProcessingCenter>().enqueueProcessingJob(...)` when a
/// [BuildContext] is available. This helper uses the bound singleton set from
/// app startup when [center] is omitted.
ProcessingCenter? _boundCenter;

void bindProcessingCenter(ProcessingCenter center) {
  _boundCenter = center;
}

Future<String> enqueueProcessingJob({
  required ProcessingJobType type,
  required List<String> mediaIds,
  Map<String, dynamic>? params,
  ProcessingCenter? center,
}) {
  final c = center ?? _boundCenter;
  if (c == null) {
    throw StateError('ProcessingCenter 尚未绑定，请先在 main 中创建并 bind');
  }
  return c.enqueueProcessingJob(
    type: type,
    mediaIds: mediaIds,
    params: params,
  );
}
