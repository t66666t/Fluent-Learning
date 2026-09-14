/// Progress snapshot for a learning unit.
class LearningUnitProgress {
  final List<String> completedMediaIds;
  final Map<String, int> watchedMsByMedia;
  final double percent;

  const LearningUnitProgress({
    this.completedMediaIds = const <String>[],
    this.watchedMsByMedia = const <String, int>{},
    this.percent = 0,
  });

  LearningUnitProgress copyWith({
    List<String>? completedMediaIds,
    Map<String, int>? watchedMsByMedia,
    double? percent,
  }) {
    return LearningUnitProgress(
      completedMediaIds: completedMediaIds ?? this.completedMediaIds,
      watchedMsByMedia: watchedMsByMedia ?? this.watchedMsByMedia,
      percent: percent ?? this.percent,
    );
  }

  bool isMediaCompleted(String mediaId) =>
      completedMediaIds.contains(mediaId);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'completedMediaIds': completedMediaIds,
      'watchedMsByMedia': watchedMsByMedia,
      'percent': percent,
    };
  }

  factory LearningUnitProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LearningUnitProgress();
    final completedRaw = json['completedMediaIds'];
    final watchedRaw = json['watchedMsByMedia'];
    return LearningUnitProgress(
      completedMediaIds: completedRaw is List
          ? completedRaw.map((e) => e.toString()).toList()
          : const <String>[],
      watchedMsByMedia: watchedRaw is Map
          ? watchedRaw.map(
              (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
            )
          : const <String, int>{},
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
    );
  }
}
