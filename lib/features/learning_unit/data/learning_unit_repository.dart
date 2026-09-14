import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:fluent_learning/features/learning_unit/models/learning_unit.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit_progress_rules.dart';
import 'package:fluent_learning/models/video_item.dart';
import 'package:fluent_learning/services/library_service.dart';

/// JSON-backed store for [LearningUnit] entities (app documents dir).
class LearningUnitRepository extends ChangeNotifier {
  LearningUnitRepository({LibraryService? libraryService})
      : _libraryService = libraryService;

  static const String _fileName = 'learning_units_v1.json';
  static const Uuid _uuid = Uuid();

  LibraryService? _libraryService;
  final Map<String, LearningUnit> _units = <String, LearningUnit>{};
  bool _initialized = false;
  File? _storeFile;
  String? _lastError;
  Timer? _progressPersistTimer;
  bool _progressDirty = false;
  final Map<String, int> _durationByMediaHint = <String, int>{};

  /// Tests can disable disk writes; production leaves this true.
  @visibleForTesting
  bool persistToDisk = true;

  bool get isInitialized => _initialized;
  String? get lastError => _lastError;

  /// Active (non-deleted) units, newest updated first.
  List<LearningUnit> get units {
    final list = _units.values.where((u) => !u.isDeleted).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  LearningUnit? getById(String id) {
    final unit = _units[id];
    if (unit == null || unit.isDeleted) return null;
    return unit;
  }

  void attachLibraryService(LibraryService library) {
    _libraryService = library;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _storeFile = File(p.join(dir.path, _fileName));
      if (await _storeFile!.exists()) {
        final raw = await _storeFile!.readAsString();
        if (raw.trim().isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map && decoded['units'] is List) {
            for (final entry in decoded['units'] as List) {
              if (entry is! Map) continue;
              final unit = LearningUnit.fromJson(
                Map<String, dynamic>.from(entry),
              );
              if (unit.id.isNotEmpty) {
                _units[unit.id] = unit;
              }
            }
          }
        }
      }
      _lastError = null;
    } catch (e) {
      _lastError = '加载学习单元失败: $e';
      debugPrint('LearningUnitRepository.init failed: $e');
    }
    _initialized = true;
    notifyListeners();
  }

  /// Pull [VideoItem.lastPositionMs] into matching units (startup / after library load).
  /// Does not bump [LearningUnit.updatedAt] so hydrate is not treated as study.
  void hydrateProgressFromLibrary() {
    var changed = false;
    for (final unit in units) {
      final next = _applyProgress(unit, touchUpdatedAt: false);
      if (next == null) continue;
      _units[unit.id] = next;
      changed = true;
    }
    if (!changed) return;
    notifyListeners();
    unawaited(_persist());
  }

  Future<LearningUnit> create({
    required String title,
    String? notes,
    required List<LearningUnitItemRef> itemRefs,
    LearningUnitSchedule schedule = const LearningUnitSchedule(),
    LearningUnitStatus status = LearningUnitStatus.active,
  }) async {
    final now = DateTime.now();
    final unit = LearningUnit(
      id: _uuid.v4(),
      title: title.trim(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      status: status,
      itemRefs: List<LearningUnitItemRef>.unmodifiable(itemRefs),
      schedule: schedule,
      progress: const LearningUnitProgress(),
      createdAt: now,
      updatedAt: now,
    );
    final hydrated = _applyProgress(unit, touchUpdatedAt: false) ?? unit;
    _units[hydrated.id] = hydrated;
    await _persist();
    notifyListeners();
    return hydrated;
  }

  Future<LearningUnit?> update(LearningUnit unit) async {
    if (!_units.containsKey(unit.id)) return null;
    final next = unit.copyWith(updatedAt: DateTime.now());
    _units[unit.id] = next;
    await _persist();
    notifyListeners();
    return next;
  }

  Future<void> softDelete(String id) async {
    final existing = _units[id];
    if (existing == null || existing.isDeleted) return;
    _units[id] = existing.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: LearningUnitStatus.archived,
    );
    await _persist();
    notifyListeners();
  }

  Future<LearningUnit?> setStatus(String id, LearningUnitStatus status) async {
    final existing = getById(id);
    if (existing == null) return null;
    final now = DateTime.now();
    final next = existing.copyWith(
      status: status,
      updatedAt: now,
      completedAt: status == LearningUnitStatus.completed ? now : null,
      clearCompletedAt: status != LearningUnitStatus.completed,
    );
    _units[id] = next;
    await _persist();
    notifyListeners();
    return next;
  }

  Future<LearningUnit?> markMediaComplete(
    String unitId,
    String mediaId, {
    bool completed = true,
  }) async {
    final existing = getById(unitId);
    if (existing == null) return null;

    final completedIds = List<String>.from(existing.progress.completedMediaIds);
    if (completed) {
      if (!completedIds.contains(mediaId)) completedIds.add(mediaId);
    } else {
      completedIds.remove(mediaId);
    }

    final withManual = existing.copyWith(
      progress: existing.progress.copyWith(completedMediaIds: completedIds),
    );
    final next = _applyProgress(withManual, touchUpdatedAt: true) ?? withManual;
    _units[unitId] = next;
    await _persist();
    notifyListeners();
    return next;
  }

  Future<LearningUnit?> recordWatchedMs(
    String unitId,
    String mediaId,
    int watchedMs,
  ) async {
    await syncMediaProgress(mediaId: mediaId, watchedMs: watchedMs);
    return getById(unitId);
  }

  /// Apply playback progress to every unit that contains [mediaId].
  Future<void> syncMediaProgress({
    required String mediaId,
    required int watchedMs,
    int durationMs = 0,
  }) async {
    if (mediaId.isEmpty) return;
    if (durationMs > 0) {
      final prev = _durationByMediaHint[mediaId] ?? 0;
      if (durationMs > prev) _durationByMediaHint[mediaId] = durationMs;
    }
    var changed = false;
    for (final unit in units) {
      final ids = resolveMediaIds(unit);
      if (!ids.contains(mediaId)) continue;
      final next = _applyProgress(
        unit,
        focusMediaId: mediaId,
        focusWatchedMs: watchedMs,
        focusDurationMs: durationMs,
        touchUpdatedAt: true,
      );
      if (next == null) continue;
      _units[unit.id] = next;
      changed = true;
    }
    if (!changed) return;
    notifyListeners();
    _scheduleProgressPersist();
  }

  bool isLeafComplete(LearningUnit unit, String mediaId) {
    return LearningUnitProgressRules.isItemComplete(
      watchedMs: leafWatchedMs(unit, mediaId),
      durationMs: _durationFor(mediaId),
      manuallyCompleted: unit.progress.isMediaCompleted(mediaId),
    );
  }

  bool isLeafManuallyCompleted(LearningUnit unit, String mediaId) =>
      unit.progress.isMediaCompleted(mediaId);

  int leafWatchedMs(
    LearningUnit unit,
    String mediaId, {
    String? focusMediaId,
    int? focusWatchedMs,
  }) {
    final stored = unit.progress.watchedMsByMedia[mediaId] ?? 0;
    final libraryPos = _libraryService?.getVideo(mediaId)?.lastPositionMs ?? 0;
    final focus = (focusMediaId == mediaId) ? (focusWatchedMs ?? 0) : 0;
    return math.max(stored, math.max(libraryPos, focus));
  }

  double leafRatio(LearningUnit unit, String mediaId) {
    return LearningUnitProgressRules.itemRatio(
      watchedMs: leafWatchedMs(unit, mediaId),
      durationMs: _durationFor(mediaId),
      manuallyCompleted: unit.progress.isMediaCompleted(mediaId),
    );
  }

  int completedLeafCount(LearningUnit unit) {
    var count = 0;
    for (final id in resolveMediaIds(unit)) {
      if (isLeafComplete(unit, id)) count++;
    }
    return count;
  }

  /// First leaf that is not complete, or null if all done / empty.
  String? nextIncompleteMediaId(LearningUnit unit) {
    for (final id in resolveMediaIds(unit)) {
      if (!isLeafComplete(unit, id)) return id;
    }
    return null;
  }

  /// Resolve item refs to leaf media IDs (order preserved, de-duped).
  List<String> resolveMediaIds(LearningUnit unit) {
    final library = _libraryService;
    final seen = <String>{};
    final result = <String>[];

    void addMedia(String? id) {
      if (id == null || id.isEmpty || seen.contains(id)) return;
      if (library != null) {
        final video = library.getVideo(id);
        if (video == null || video.isRecycled) return;
      }
      seen.add(id);
      result.add(id);
    }

    void walkFolder(String folderId, bool includeNested) {
      if (library == null) return;
      final videos = library.getVideosInFolder(folderId);
      for (final v in videos) {
        addMedia(v.id);
      }
      if (!includeNested) return;
      final collection = library.getCollection(folderId);
      if (collection == null) return;
      for (final childId in collection.childrenIds) {
        if (library.getCollection(childId) != null) {
          walkFolder(childId, true);
        }
      }
    }

    for (final ref in unit.itemRefs) {
      if (ref.isMedia) {
        addMedia(ref.mediaId);
      } else if (ref.isFolder) {
        walkFolder(ref.folderId!, ref.includeNested);
      }
    }
    return result;
  }

  List<VideoItem> resolveMediaItems(LearningUnit unit) {
    final library = _libraryService;
    if (library == null) return const <VideoItem>[];
    final items = <VideoItem>[];
    for (final id in resolveMediaIds(unit)) {
      final video = library.getVideo(id);
      if (video != null) items.add(video);
    }
    return items;
  }

  /// Units with a dueDate on the given calendar day (local).
  List<LearningUnit> unitsDueOn(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return units.where((u) {
      final due = u.schedule.dueDate;
      if (due == null) return false;
      return !due.isBefore(start) && due.isBefore(end);
    }).toList();
  }

  int _durationFor(String mediaId, {String? focusMediaId, int? focusDurationMs}) {
    if (focusMediaId == mediaId &&
        focusDurationMs != null &&
        focusDurationMs > 0) {
      return focusDurationMs;
    }
    final fromLibrary = _libraryService?.getVideo(mediaId)?.durationMs ?? 0;
    final hint = _durationByMediaHint[mediaId] ?? 0;
    return math.max(fromLibrary, hint);
  }

  /// Returns an updated unit when progress/status actually changed; otherwise null.
  LearningUnit? _applyProgress(
    LearningUnit unit, {
    String? focusMediaId,
    int? focusWatchedMs,
    int? focusDurationMs,
    bool touchUpdatedAt = true,
  }) {
    final ids = resolveMediaIds(unit);
    final watched = Map<String, int>.from(unit.progress.watchedMsByMedia);
    final completedIds = List<String>.from(unit.progress.completedMediaIds);

    if (focusMediaId != null &&
        focusWatchedMs != null &&
        ids.contains(focusMediaId)) {
      final prev = watched[focusMediaId] ?? 0;
      if (focusWatchedMs > prev) {
        watched[focusMediaId] = focusWatchedMs;
      }
    }

    final ratios = <double>[];
    var completeCount = 0;
    for (final id in ids) {
      final watchedMs = leafWatchedMs(
        unit.copyWith(
          progress: unit.progress.copyWith(watchedMsByMedia: watched),
        ),
        id,
        focusMediaId: focusMediaId,
        focusWatchedMs: focusWatchedMs,
      );
      if (watchedMs > (watched[id] ?? 0)) {
        watched[id] = watchedMs;
      }
      final durationMs = _durationFor(
        id,
        focusMediaId: focusMediaId,
        focusDurationMs: focusDurationMs,
      );
      final manual = completedIds.contains(id);
      final ratio = LearningUnitProgressRules.itemRatio(
        watchedMs: watchedMs,
        durationMs: durationMs,
        manuallyCompleted: manual,
      );
      ratios.add(ratio);
      if (LearningUnitProgressRules.isItemComplete(
        watchedMs: watchedMs,
        durationMs: durationMs,
        manuallyCompleted: manual,
      )) {
        completeCount++;
      }
    }

    final percent = LearningUnitProgressRules.aggregatePercent(ratios);
    var status = unit.status;
    DateTime? completedAt = unit.completedAt;
    if (ids.isNotEmpty && completeCount >= ids.length) {
      status = LearningUnitStatus.completed;
      completedAt ??= DateTime.now();
    } else if (status == LearningUnitStatus.completed) {
      status = LearningUnitStatus.active;
      completedAt = null;
    } else if (status == LearningUnitStatus.planned &&
        (percent > 0 || (focusWatchedMs ?? 0) > 0)) {
      status = LearningUnitStatus.active;
    }

    final sameWatched = _mapEquals(watched, unit.progress.watchedMsByMedia);
    final sameCompleted = listEquals(completedIds, unit.progress.completedMediaIds);
    final samePercent = (percent - unit.progress.percent).abs() < 0.0005;
    if (sameWatched &&
        sameCompleted &&
        samePercent &&
        status == unit.status &&
        completedAt == unit.completedAt) {
      return null;
    }

    return unit.copyWith(
      status: status,
      completedAt: completedAt,
      clearCompletedAt: completedAt == null,
      updatedAt: touchUpdatedAt ? DateTime.now() : unit.updatedAt,
      progress: unit.progress.copyWith(
        completedMediaIds: completedIds,
        watchedMsByMedia: watched,
        percent: percent,
      ),
    );
  }

  bool _mapEquals(Map<String, int> a, Map<String, int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  void _scheduleProgressPersist() {
    _progressDirty = true;
    _progressPersistTimer?.cancel();
    _progressPersistTimer = Timer(const Duration(seconds: 2), () {
      if (!_progressDirty) return;
      _progressDirty = false;
      unawaited(_persist());
    });
  }

  Future<void> _persist() async {
    if (!persistToDisk) return;
    try {
      final file = _storeFile;
      if (file == null) {
        final dir = await getApplicationDocumentsDirectory();
        _storeFile = File(p.join(dir.path, _fileName));
      }
      final payload = <String, dynamic>{
        'version': 1,
        'units': _units.values.map((u) => u.toJson()).toList(),
      };
      final target = _storeFile!;
      final staging = File('${target.path}.tmp');
      await staging.writeAsString(
        const JsonEncoder.withIndent('  ').convert(payload),
        flush: true,
      );
      if (await target.exists()) {
        await target.delete();
      }
      await staging.rename(target.path);
      _lastError = null;
    } catch (e) {
      _lastError = '保存学习单元失败: $e';
      debugPrint('LearningUnitRepository.persist failed: $e');
    }
  }
}
