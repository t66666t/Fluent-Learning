import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fluent_learning/system/model_center/model_descriptor.dart';
import 'package:fluent_learning/system/model_center/model_kind.dart';

/// System Model Center — catalog, active selection, and thin resolve.
///
/// Features must not hardcode ASR/translation implementations; ask here.
class ModelCenter extends ChangeNotifier {
  ModelCenter();

  static const String _prefsActivePrefix = 'model_center_active_v1_';
  static const String _prefsLocalPathPrefix = 'model_center_local_path_v1_';
  static const String _prefsApiBasePrefix = 'model_center_api_base_v1_';
  static const String _prefsApiKeyPrefix = 'model_center_api_key_v1_';

  static const String bcutAsrId = 'bcut_asr';
  static const String localWhisperId = 'local_whisper';

  static const String googleTranslateId = 'google_translate';
  static const String bingTranslateId = 'bing_translate';
  static const String myMemoryTranslateId = 'mymemory_translate';
  static const String so360TranslateId = 'so360_translate';
  static const String reversoTranslateId = 'reverso_translate';

  /// Maps catalog translation ids → [SubtitleTranslateProvider.name].
  static const Map<String, String> translationProviderNames =
      <String, String>{
    googleTranslateId: 'google',
    bingTranslateId: 'bing',
    myMemoryTranslateId: 'mymemory',
    so360TranslateId: 'so360',
    reversoTranslateId: 'reverso',
  };

  static const List<ModelDescriptor> _builtin = <ModelDescriptor>[
    ModelDescriptor(
      id: bcutAsrId,
      kind: ModelKind.transcription,
      displayName: 'B站必剪 ASR',
      description: '现有在线转录（bcut / transcription_manager）',
    ),
    ModelDescriptor(
      id: localWhisperId,
      kind: ModelKind.transcription,
      displayName: '本地 Whisper（预留）',
      description: '本地模型路径见下方配置；尚未接入执行',
      available: false,
    ),
    ModelDescriptor(
      id: googleTranslateId,
      kind: ModelKind.translation,
      displayName: 'Google 翻译',
      description: '字幕翻译（subtitle_translation_service · google）',
    ),
    ModelDescriptor(
      id: bingTranslateId,
      kind: ModelKind.translation,
      displayName: '微软翻译 (Bing)',
      description: '字幕翻译（subtitle_translation_service · bing）',
    ),
    ModelDescriptor(
      id: myMemoryTranslateId,
      kind: ModelKind.translation,
      displayName: 'MyMemory',
      description: '字幕翻译（subtitle_translation_service · mymemory）',
    ),
    ModelDescriptor(
      id: so360TranslateId,
      kind: ModelKind.translation,
      displayName: '360 翻译',
      description: '中英互译（subtitle_translation_service · so360）',
    ),
    ModelDescriptor(
      id: reversoTranslateId,
      kind: ModelKind.translation,
      displayName: 'Reverso',
      description: '字幕翻译（subtitle_translation_service · reverso）',
    ),
  ];

  final Map<ModelKind, String?> _activeIds = <ModelKind, String?>{
    ModelKind.transcription: bcutAsrId,
    ModelKind.translation: googleTranslateId,
  };

  final Map<ModelKind, ModelKindRemoteConfig> _remoteConfigs =
      <ModelKind, ModelKindRemoteConfig>{
    for (final kind in ModelKind.values) kind: const ModelKindRemoteConfig(),
  };

  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    for (final kind in ModelKind.values) {
      final stored = prefs.getString('$_prefsActivePrefix${kind.name}');
      if (stored != null && stored.isNotEmpty) {
        // Only restore if still in catalog (or QA which has empty catalog).
        if (kind == ModelKind.qa ||
            _builtin.any((m) => m.kind == kind && m.id == stored)) {
          _activeIds[kind] = stored;
        }
      }
      _remoteConfigs[kind] = ModelKindRemoteConfig(
        localModelPath:
            prefs.getString('$_prefsLocalPathPrefix${kind.name}') ?? '',
        apiBaseUrl: prefs.getString('$_prefsApiBasePrefix${kind.name}') ?? '',
        apiKey: prefs.getString('$_prefsApiKeyPrefix${kind.name}') ?? '',
      );
    }
    _activeIds.putIfAbsent(ModelKind.transcription, () => bcutAsrId);
    _activeIds.putIfAbsent(ModelKind.translation, () => googleTranslateId);
    // QA has no models yet — leave null / unset.
    _initialized = true;
    notifyListeners();
  }

  /// List providers for [kind]. QA returns empty (UI shows 「未配置」).
  List<ModelDescriptor> list(ModelKind kind) {
    return _builtin.where((m) => m.kind == kind).toList(growable: false);
  }

  String? getActive(ModelKind kind) => _activeIds[kind];

  Future<void> setActive(ModelKind kind, String modelId) async {
    final options = list(kind);
    if (options.isEmpty) {
      throw StateError('ModelKind.${kind.name} 暂无可用模型');
    }
    ModelDescriptor? match;
    for (final m in options) {
      if (m.id == modelId) {
        match = m;
        break;
      }
    }
    if (match == null) {
      throw ArgumentError.value(modelId, 'modelId', '不在 ${kind.name} 目录中');
    }
    if (!match.available) {
      throw StateError('${match.displayName} 尚未可用');
    }
    _activeIds[kind] = modelId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsActivePrefix${kind.name}', modelId);
    debugPrint(
      'ModelCenter: active ${kind.name} → $modelId (${match.displayName})',
    );
    notifyListeners();
  }

  /// Resolve the active catalog entry for [kind], or `null` if unset/unavailable.
  ModelDescriptor? resolve(ModelKind kind) {
    final id = getActive(kind);
    if (id == null) return null;
    for (final m in list(kind)) {
      if (m.id == id) {
        return m.available ? m : null;
      }
    }
    return null;
  }

  /// Provider name for subtitle translation service (`google`, `bing`, …).
  String? resolveTranslationProviderName() {
    final active = resolve(ModelKind.translation);
    if (active == null) return null;
    return translationProviderNames[active.id];
  }

  ModelKindRemoteConfig getRemoteConfig(ModelKind kind) =>
      _remoteConfigs[kind] ?? const ModelKindRemoteConfig();

  Future<void> setRemoteConfig(
    ModelKind kind,
    ModelKindRemoteConfig config,
  ) async {
    _remoteConfigs[kind] = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefsLocalPathPrefix${kind.name}',
      config.localModelPath,
    );
    await prefs.setString(
      '$_prefsApiBasePrefix${kind.name}',
      config.apiBaseUrl,
    );
    await prefs.setString(
      '$_prefsApiKeyPrefix${kind.name}',
      config.apiKey,
    );
    notifyListeners();
  }

  Future<void> setLocalModelPath(ModelKind kind, String path) async {
    final current = getRemoteConfig(kind);
    await setRemoteConfig(kind, current.copyWith(localModelPath: path));
  }

  Future<void> setApiBaseUrl(ModelKind kind, String url) async {
    final current = getRemoteConfig(kind);
    await setRemoteConfig(kind, current.copyWith(apiBaseUrl: url));
  }

  Future<void> setApiKey(ModelKind kind, String key) async {
    final current = getRemoteConfig(kind);
    await setRemoteConfig(kind, current.copyWith(apiKey: key));
  }
}
