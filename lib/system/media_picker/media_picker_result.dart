/// Result returned by [showAppMediaPicker] on confirm; `null` on cancel.
class MediaPickerResult {
  /// Leaf media IDs after expanding any selected folders.
  final List<String> mediaIds;

  /// Folder IDs the user explicitly fully-selected (optional bookkeeping).
  final List<String> folderIds;

  const MediaPickerResult({
    required this.mediaIds,
    this.folderIds = const <String>[],
  });

  int get totalSelectedCount => mediaIds.length;
}
