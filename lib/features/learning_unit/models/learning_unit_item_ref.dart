/// Reference to either a single media item or a library folder.
class LearningUnitItemRef {
  final String? mediaId;
  final String? folderId;
  final bool includeNested;

  const LearningUnitItemRef.media(this.mediaId)
      : folderId = null,
        includeNested = false;

  const LearningUnitItemRef.folder(
    this.folderId, {
    this.includeNested = true,
  }) : mediaId = null;

  bool get isMedia => mediaId != null && mediaId!.isNotEmpty;
  bool get isFolder => folderId != null && folderId!.isNotEmpty;

  Map<String, dynamic> toJson() {
    if (isFolder) {
      return <String, dynamic>{
        'folderId': folderId,
        'includeNested': includeNested,
      };
    }
    return <String, dynamic>{'mediaId': mediaId};
  }

  factory LearningUnitItemRef.fromJson(Map<String, dynamic> json) {
    final folderId = json['folderId'] as String?;
    if (folderId != null && folderId.isNotEmpty) {
      return LearningUnitItemRef.folder(
        folderId,
        includeNested: json['includeNested'] as bool? ?? true,
      );
    }
    return LearningUnitItemRef.media(json['mediaId'] as String? ?? '');
  }
}
