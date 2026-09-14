import 'dart:convert';

import 'package:fluent_learning/domain/sync/media_sync_metadata.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit.dart';

/// Versioned metadata-only sync bundle (LearningUnits + optional media rows).
///
/// Never includes video/audio binary content — only JSON field metadata.
class MetadataSyncBundle {
  static const String formatId = 'fluent_learning_metadata_v1';

  MetadataSyncBundle({
    required this.exportedAt,
    required this.learningUnits,
    this.mediaMetadata = const <MediaSyncMetadata>[],
    this.format = formatId,
  });

  final String format;
  final DateTime exportedAt;
  final List<LearningUnit> learningUnits;
  final List<MediaSyncMetadata> mediaMetadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'format': format,
      'exportedAt': exportedAt.toIso8601String(),
      'learningUnits':
          learningUnits.map((u) => u.toSyncJson()).toList(growable: false),
      if (mediaMetadata.isNotEmpty)
        'mediaMetadata': mediaMetadata
            .map((m) => m.toSyncJson())
            .toList(growable: false),
    };
  }

  String encodePretty() =>
      const JsonEncoder.withIndent('  ').convert(toJson());

  static MetadataSyncBundle decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Metadata sync JSON must be an object');
    }
    return MetadataSyncBundle.fromJson(Map<String, dynamic>.from(decoded));
  }

  factory MetadataSyncBundle.fromJson(Map<String, dynamic> json) {
    final format = json['format'] as String? ?? formatId;
    if (format != formatId && !format.startsWith('fluent_learning_metadata_')) {
      throw FormatException('Unsupported metadata sync format: $format');
    }

    final unitsRaw = json['learningUnits'] ?? json['units'];
    final units = <LearningUnit>[];
    if (unitsRaw is List) {
      for (final entry in unitsRaw) {
        if (entry is! Map) continue;
        final unit = LearningUnit.fromJson(Map<String, dynamic>.from(entry));
        if (unit.id.isNotEmpty) units.add(unit);
      }
    }

    final mediaRaw = json['mediaMetadata'];
    final media = <MediaSyncMetadata>[];
    if (mediaRaw is List) {
      for (final entry in mediaRaw) {
        if (entry is! Map) continue;
        final row =
            MediaSyncMetadata.fromSyncJson(Map<String, dynamic>.from(entry));
        if (row.id.isNotEmpty) media.add(row);
      }
    }

    return MetadataSyncBundle(
      format: format,
      exportedAt: DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime.now(),
      learningUnits: units,
      mediaMetadata: media,
    );
  }

  /// Build an export bundle from in-memory entities.
  static MetadataSyncBundle export({
    required Iterable<LearningUnit> learningUnits,
    Iterable<MediaSyncMetadata> mediaMetadata = const <MediaSyncMetadata>[],
    DateTime? exportedAt,
  }) {
    return MetadataSyncBundle(
      exportedAt: exportedAt ?? DateTime.now(),
      learningUnits: List<LearningUnit>.unmodifiable(learningUnits),
      mediaMetadata: List<MediaSyncMetadata>.unmodifiable(mediaMetadata),
    );
  }
}

/// Result of applying a [MetadataSyncBundle] onto a LearningUnit store.
class MetadataSyncImportResult {
  const MetadataSyncImportResult({
    required this.upserted,
    required this.skipped,
    required this.mediaRows,
  });

  final int upserted;
  final int skipped;
  final int mediaRows;
}
