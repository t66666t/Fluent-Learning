import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fluent_learning/system/model_center/model_descriptor.dart';
import 'package:fluent_learning/system/model_center/model_kind.dart';

/// System Model Center — catalog, active selection, and thin resolve.
///
/// Features must not hardcode ASR/translation implementations; ask here.
class ModelCenter extends ChangeNotifier {
  ModelCenter();

  static const String _prefsPrefix = 'model_center_active_v1_';

  static const String bcutAsrId = 'bcut_asr';
  static const String googleTranslateId = 'google_translate';

  static const List<ModelDescriptor> _builtin = <ModelDescriptor>[
    ModelDescriptor(
      id: bcutAsrId,
      kind: ModelKind.transcription,
      displayName: 'B站必剪 ASR',
      description: '现有在线转录（bcut / transcription_manager）',
    ),
    ModelDescriptor(
      id: googleTranslateId,
      kind: ModelKind.translation,
      displayName: 'Google 翻译',
      description: '字幕翻译（subtitle_translation_service）',
    ),
  ];

  final Map<ModelKind, String?> _activeIds = <ModelKind, String?>{
    ModelKind.transcription: bcutAsrId,
    ModelKind.translation: googleTranslateId,
  };
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    for (final kind in ModelKind.values) {
      final stored = prefs.getString('$_prefsPrefix${kind.name}');
      if (stored != null && stored.isNotEmpty) {
        _activeIds[kind] = stored;
      }
    }
    _activeIds.putIfAbsent(ModelKind.transcription, () => bcutAsrId);
    _activeIds.putIfAbsent(ModelKind.translation, () => googleTranslateId);
    // QA has no models yet — leave null / unset.
    _initialized = true;
    notifyListeners();
  }

  /// List providers for [kind]. QA returns empty (UI shows 「即将支持」).
  List<ModelDescriptor> list(ModelKind kind) {
    return _builtin.where((m) => m.kind == kind).toList(growable: false);
  }

  String? getActive(ModelKind kind) => _activeIds[kind];

  Future<void> setActive(ModelKind kind, String modelId) async {
    final options = list(kind);
    if (options.isEmpty) {
      throw StateError('ModelKind.${kind.name} 暂无可用模型');
    }
    if (!options.any((m) => m.id == modelId)) {
      throw ArgumentError.value(modelId, 'modelId', '不在 ${kind.name} 目录中');
    }
    _activeIds[kind] = modelId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsPrefix${kind.name}', modelId);
    notifyListeners();
  }

  /// Resolve the active catalog entry for [kind], or `null` if unset/unavailable.
  ModelDescriptor? resolve(ModelKind kind) {
    final id = getActive(kind);
    if (id == null) return null;
    for (final m in list(kind)) {
      if (m.id == id) return m;
    }
    return null;
  }
}
