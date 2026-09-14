import 'dart:async';

import 'package:fluent_learning/features/learning_unit/data/learning_unit_repository.dart';
import 'package:fluent_learning/services/library_service.dart';

/// Wires [LibraryService.updateVideoProgress] into [LearningUnitRepository]
/// without touching playback internals.
class LearningUnitProgressBridge {
  LearningUnitProgressBridge({
    required LibraryService library,
    required LearningUnitRepository repository,
  })  : _library = library,
        _repository = repository;

  final LibraryService _library;
  final LearningUnitRepository _repository;
  bool _attached = false;

  void attach() {
    if (_attached) return;
    _library.onVideoProgressUpdated = _onProgress;
    _attached = true;
  }

  void detach() {
    if (!_attached) return;
    if (identical(_library.onVideoProgressUpdated, _onProgress)) {
      _library.onVideoProgressUpdated = null;
    }
    _attached = false;
  }

  void _onProgress(String id, int positionMs) {
    final video = _library.getVideo(id);
    unawaited(
      _repository.syncMediaProgress(
        mediaId: id,
        watchedMs: positionMs,
        durationMs: video?.durationMs ?? 0,
      ),
    );
  }
}
