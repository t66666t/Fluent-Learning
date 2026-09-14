import 'package:flutter/foundation.dart';

import 'package:fluent_learning/services/library_service.dart';
import 'package:fluent_learning/services/settings_service.dart';
import 'package:fluent_learning/services/transcription_manager.dart';
import 'package:fluent_learning/system/processing_center/processing_job_type.dart';

/// System Processing Center — thin queue facade over existing managers.
///
/// MVP maps [ProcessingJobType.transcription] to [TranscriptionManager].
class ProcessingCenter extends ChangeNotifier {
  ProcessingCenter({
    required TranscriptionManager transcriptionManager,
    required LibraryService libraryService,
    required SettingsService settingsService,
  })  : _transcriptionManager = transcriptionManager,
        _libraryService = libraryService,
        _settingsService = settingsService;

  final TranscriptionManager _transcriptionManager;
  final LibraryService _libraryService;
  final SettingsService _settingsService;

  int _jobSeq = 0;

  /// Enqueue a processing job. Returns a local job id string.
  ///
  /// For transcription, each [mediaIds] entry is resolved via [LibraryService].
  /// Path-only callers may pass `params['videoPath']` (+ optional `videoId`).
  Future<String> enqueueProcessingJob({
    required ProcessingJobType type,
    required List<String> mediaIds,
    Map<String, dynamic>? params,
  }) async {
    final jobId = 'pc_${DateTime.now().millisecondsSinceEpoch}_${++_jobSeq}';

    switch (type) {
      case ProcessingJobType.transcription:
        await _enqueueTranscription(
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
    required List<String> mediaIds,
    Map<String, dynamic>? params,
  }) async {
    final autoStart = params?['autoStart'] as bool? ?? true;
    final autoCache =
        params?['autoCache'] as bool? ?? _settingsService.autoCacheSubtitles;

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
      // Skip if already added via videoPath + same id.
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
