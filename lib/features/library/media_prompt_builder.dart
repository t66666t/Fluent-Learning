import 'package:fluent_learning/models/video_item.dart';
import 'package:path/path.dart' as p;

/// Builds a compact natural-language prompt fragment from a [VideoItem]
/// for Q&A / classification features (P2-quality is fine).
class MediaPromptBuilder {
  const MediaPromptBuilder._();

  static String from(VideoItem item) {
    final buffer = StringBuffer();
    buffer.writeln('媒体标题: ${item.effectiveDisplayName}');
    final fileName = item.effectiveFileName;
    if (fileName.isNotEmpty) {
      buffer.writeln('文件名: $fileName');
    }
    if (item.durationMs > 0) {
      buffer.writeln('时长: ${_formatDuration(item.durationMs)}');
    }
    buffer.writeln('类型: ${item.type.name}');

    if (item.chapters.isNotEmpty) {
      buffer.writeln('章节:');
      final limit = item.chapters.length > 12 ? 12 : item.chapters.length;
      for (var i = 0; i < limit; i++) {
        final chapter = item.chapters[i];
        final title = chapter.title.trim().isEmpty
            ? '第${i + 1}章'
            : chapter.title.trim();
        buffer.writeln(
          '  - ${_formatDuration(chapter.startMs)} $title',
        );
      }
      if (item.chapters.length > limit) {
        buffer.writeln('  - …共 ${item.chapters.length} 章');
      }
    }

    final subtitleSummary = _subtitleOverview(item);
    if (subtitleSummary.isNotEmpty) {
      buffer.writeln('字幕概况: $subtitleSummary');
    }

    if (item.width != null && item.height != null) {
      buffer.writeln('分辨率: ${item.width}x${item.height}');
    }
    if (item.codec != null && item.codec!.trim().isNotEmpty) {
      buffer.writeln('编码: ${item.codec}');
    }

    return buffer.toString().trim();
  }

  static String _subtitleOverview(VideoItem item) {
    final parts = <String>[];
    if (item.subtitlePath != null && item.subtitlePath!.isNotEmpty) {
      parts.add('主字幕 ${p.basename(item.subtitlePath!)}');
    }
    if (item.secondarySubtitlePath != null &&
        item.secondarySubtitlePath!.isNotEmpty) {
      parts.add('副字幕 ${p.basename(item.secondarySubtitlePath!)}');
    }
    final managed = item.managedSubtitleAssets.length;
    if (managed > 0) {
      parts.add('托管字幕 $managed 个');
    }
    final localGroups = item.localSubtitleGroups.length;
    if (localGroups > 0) {
      parts.add('本地字幕组 $localGroups');
    }
    final downloadGroups = item.downloadAssociatedSubtitles.length;
    if (downloadGroups > 0) {
      parts.add('下载关联字幕 $downloadGroups');
    }
    if (item.danmakuPath != null && item.danmakuPath!.isNotEmpty) {
      parts.add('含弹幕');
    }
    return parts.join('；');
  }

  static String _formatDuration(int ms) {
    if (ms <= 0) return '0:00';
    final totalSeconds = ms ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
