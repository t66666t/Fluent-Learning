import 'package:fluent_learning/models/video_item.dart';

/// Request options for [showAppMediaPicker].
class MediaPickerRequest {
  /// When true, multiple media (and folders, if allowed) may be selected.
  final bool multiSelect;

  /// When true, folders may be checked; selecting a folder expands nested
  /// leaves into [MediaPickerResult.mediaIds].
  final bool allowFolders;

  /// If non-null and non-empty, only media of these types are shown.
  final Set<MediaType>? typeFilter;

  /// Media IDs that cannot be selected (e.g. already in a processing queue).
  final Set<String> excludeIds;

  /// Dialog title. Defaults to 「选择媒体」.
  final String? title;

  /// Confirm button label prefix. Defaults to 「确认」.
  final String? confirmLabel;

  /// Optional folder to expand on open (e.g. current collection).
  final String? initialFolderId;

  const MediaPickerRequest({
    this.multiSelect = true,
    this.allowFolders = true,
    this.typeFilter,
    this.excludeIds = const <String>{},
    this.title,
    this.confirmLabel,
    this.initialFolderId,
  });
}
