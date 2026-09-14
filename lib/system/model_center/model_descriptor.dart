import 'package:fluent_learning/system/model_center/model_kind.dart';

/// Thin catalog entry for a selectable model provider.
class ModelDescriptor {
  const ModelDescriptor({
    required this.id,
    required this.kind,
    required this.displayName,
    this.description = '',
    this.available = true,
  });

  final String id;
  final ModelKind kind;
  final String displayName;
  final String description;
  final bool available;
}

/// Concept alias: transcription provider entry in the catalog (e.g. bcut ASR).
typedef TranscriptionModelProvider = ModelDescriptor;

/// Concept alias: translation provider entry (e.g. Google via subtitle_translation_service).
typedef TranslationModelProvider = ModelDescriptor;

/// Reserved local-model / API settings for a [ModelKind] (stored, not executed).
class ModelKindRemoteConfig {
  const ModelKindRemoteConfig({
    this.localModelPath = '',
    this.apiBaseUrl = '',
    this.apiKey = '',
  });

  final String localModelPath;
  final String apiBaseUrl;
  final String apiKey;

  bool get hasAny =>
      localModelPath.trim().isNotEmpty ||
      apiBaseUrl.trim().isNotEmpty ||
      apiKey.trim().isNotEmpty;

  ModelKindRemoteConfig copyWith({
    String? localModelPath,
    String? apiBaseUrl,
    String? apiKey,
  }) {
    return ModelKindRemoteConfig(
      localModelPath: localModelPath ?? this.localModelPath,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      apiKey: apiKey ?? this.apiKey,
    );
  }
}
