import 'package:fluent_learning/domain/sync/sync_entity.dart';
import 'package:fluent_learning/models/video_item.dart';

/// Lightweight media row for metadata sync — paths are hints only, never blobs.
class MediaSyncMetadata implements SyncEntity {
  MediaSyncMetadata({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    this.revision,
    required this.title,
    required this.mediaType,
    required this.durationMs,
    this.parentId,
    this.sourceFingerprint,
    this.pathHint,
    this.displayName,
  });

  @override
  final String id;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? deletedAt;
  @override
  final int? revision;

  final String title;
  final String mediaType;
  final int durationMs;
  final String? parentId;
  final String? sourceFingerprint;

  /// Local path string for restore hints on the same device — not a file export.
  final String? pathHint;
  final String? displayName;

  factory MediaSyncMetadata.fromVideoItem(VideoItem item) {
    final deletedEpoch = item.syncDeletedAt ??
        (item.isRecycled ? item.recycleTime : null);
    return MediaSyncMetadata(
      id: item.id,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(item.lastUpdated),
      deletedAt: deletedEpoch == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(deletedEpoch),
      revision: item.syncRevision,
      title: item.title,
      mediaType: item.type.name,
      durationMs: item.durationMs,
      parentId: item.parentId,
      sourceFingerprint: item.sourceFingerprint,
      pathHint: item.path,
      displayName: item.displayName,
    );
  }

  @override
  Map<String, dynamic> toSyncJson() {
    return <String, dynamic>{
      'id': id,
      'updatedAt': updatedAt.toIso8601String(),
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      if (revision != null) 'revision': revision,
      'title': title,
      'mediaType': mediaType,
      'durationMs': durationMs,
      if (parentId != null) 'parentId': parentId,
      if (sourceFingerprint != null) 'sourceFingerprint': sourceFingerprint,
      if (pathHint != null) 'pathHint': pathHint,
      if (displayName != null) 'displayName': displayName,
    };
  }

  factory MediaSyncMetadata.fromSyncJson(Map<String, dynamic> json) {
    return MediaSyncMetadata(
      id: json['id'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
      revision: (json['revision'] as num?)?.toInt(),
      title: json['title'] as String? ?? '',
      mediaType: json['mediaType'] as String? ?? 'video',
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      parentId: json['parentId'] as String?,
      sourceFingerprint: json['sourceFingerprint'] as String?,
      pathHint: json['pathHint'] as String?,
      displayName: json['displayName'] as String?,
    );
  }
}
