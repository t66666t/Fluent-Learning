import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:fluent_learning/features/learning_unit/models/learning_unit.dart';
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
    _units[unit.id] = unit;
    await _persist();
    notifyListeners();
    return unit;
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

    final resolved = resolveMediaIds(existing);
    final completedIds = List<String>.from(existing.progress.completedMediaIds);
    if (completed) {
      if (!completedIds.contains(mediaId)) completedIds.add(mediaId);
    } else {
      completedIds.remove(mediaId);
    }

    final percent = resolved.isEmpty
        ? 0.0
        : (completedIds.where(resolved.contains).length / resolved.length)
            .clamp(0.0, 1.0);

    var status = existing.status;
    DateTime? completedAt = existing.completedAt;
    if (percent >= 1.0 && resolved.isNotEmpty) {
      status = LearningUnitStatus.completed;
      completedAt = DateTime.now();
    } else if (status == LearningUnitStatus.completed) {
      status = LearningUnitStatus.active;
      completedAt = null;
    } else if (status == LearningUnitStatus.planned) {
      status = LearningUnitStatus.active;
    }

    final next = existing.copyWith(
      status: status,
      completedAt: completedAt,
      clearCompletedAt: completedAt == null,
      updatedAt: DateTime.now(),
      progress: existing.progress.copyWith(
        completedMediaIds: completedIds,
        percent: percent,
      ),
    );
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
    final existing = getById(unitId);
    if (existing == null) return null;
    final map = Map<String, int>.from(existing.progress.watchedMsByMedia);
    final prev = map[mediaId] ?? 0;
    if (watchedMs <= prev) return existing;
    map[mediaId] = watchedMs;
    final next = existing.copyWith(
      updatedAt: DateTime.now(),
      progress: existing.progress.copyWith(watchedMsByMedia: map),
      status: existing.status == LearningUnitStatus.planned
          ? LearningUnitStatus.active
          : existing.status,
    );
    _units[unitId] = next;
    await _persist();
    notifyListeners();
    return next;
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

  Future<void> _persist() async {
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
