import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:fluent_learning/features/library/media_prompt_builder.dart';
import 'package:fluent_learning/models/video_item.dart';
import 'package:fluent_learning/services/library_service.dart';
import 'package:fluent_learning/app/responsive.dart';
import 'package:fluent_learning/core/theme_tokens.dart';

/// Read-only media properties page for a library [VideoItem].
class MediaPropertiesPage extends StatelessWidget {
  const MediaPropertiesPage({super.key, required this.videoId});

  final String videoId;

  static Future<void> open(BuildContext context, String videoId) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MediaPropertiesPage(videoId: videoId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryService>(
      builder: (context, library, _) {
        final item = library.getVideo(videoId);
        if (item == null) {
          return Scaffold(
            backgroundColor: AppColors.scaffold,
            appBar: AppBar(
              title: const Text('媒体属性'),
              backgroundColor: AppColors.elevated,
              elevation: 0,
            ),
            body: const Center(
              child: Text(
                '媒体不存在或已删除',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
          );
        }

        final libraryBreadcrumb = _libraryBreadcrumb(library, item);

        return Scaffold(
          backgroundColor: AppColors.scaffold,
          appBar: AppBar(
            title: const Text('媒体属性'),
            backgroundColor: AppColors.elevated,
            elevation: 0,
            actions: [
              IconButton(
                tooltip: '复制 Prompt',
                icon: const Icon(Icons.content_copy_outlined),
                onPressed: () async {
                  final prompt = MediaPromptBuilder.from(item);
                  await Clipboard.setData(ClipboardData(text: prompt));
                },
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              context.isCompact ? 12 : (context.isExpanded ? 24 : 16),
              12,
              context.isCompact ? 12 : (context.isExpanded ? 24 : 16),
              32,
            ),
            children: [
              _Section(
                title: '库内位置',
                children: [
                  _Row(label: '所在位置', value: libraryBreadcrumb),
                  _Row(
                    label: '字幕概况',
                    value: _subtitleOverview(item),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: '基本信息',
                children: [
                  _Row(label: '显示名称', value: item.effectiveDisplayName),
                  _Row(label: '标题', value: item.title),
                  _Row(label: '文件名', value: item.effectiveFileName),
                  _Row(label: '路径', value: item.path, mono: true),
                  if (item.playbackPath != null &&
                      item.playbackPath!.isNotEmpty &&
                      item.playbackPath != item.path)
                    _Row(
                      label: '播放路径',
                      value: item.playbackPath!,
                      mono: true,
                    ),
                  _Row(label: '类型', value: item.type.name),
                  _Row(
                    label: '时长',
                    value: _formatDuration(item.durationMs),
                  ),
                  _Row(
                    label: '进度',
                    value: _formatProgress(item),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: '字幕概况',
                children: [
                  _Row(
                    label: '概览',
                    value: _subtitleOverview(item),
                  ),
                  if (item.subtitlePath != null)
                    _Row(
                      label: '主字幕',
                      value: p.basename(item.subtitlePath!),
                    ),
                  if (item.secondarySubtitlePath != null)
                    _Row(
                      label: '副字幕',
                      value: p.basename(item.secondarySubtitlePath!),
                    ),
                  if (item.managedSubtitleAssets.isNotEmpty)
                    _Row(
                      label: '托管字幕',
                      value: '${item.managedSubtitleAssets.length} 个',
                    ),
                  if (item.danmakuPath != null)
                    _Row(
                      label: '弹幕',
                      value: p.basename(item.danmakuPath!),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: '技术属性',
                children: [
                  _Row(
                    label: '分辨率',
                    value: item.width != null && item.height != null
                        ? '${item.width}×${item.height}'
                        : '未探测',
                  ),
                  _Row(
                    label: '帧率',
                    value: item.frameRate != null
                        ? '${item.frameRate!.toStringAsFixed(2)} fps'
                        : '未探测',
                  ),
                  _Row(
                    label: '码率',
                    value: item.bitRate != null
                        ? _formatBitRate(item.bitRate!)
                        : '未探测',
                  ),
                  _Row(
                    label: '编码',
                    value: (item.codec != null && item.codec!.isNotEmpty)
                        ? item.codec!
                        : '未知',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: '时间',
                children: [
                  _Row(
                    label: '发布时间',
                    value: _formatEpoch(item.publishedAt),
                  ),
                  _Row(
                    label: '导入时间',
                    value: _formatEpoch(item.importedAt),
                  ),
                  _Row(
                    label: '上次播放',
                    value: _formatEpoch(item.lastPlayedAt),
                  ),
                  _Row(
                    label: '最近更新',
                    value: _formatEpoch(item.lastUpdated),
                  ),
                ],
              ),
              if (item.chapters.isNotEmpty) ...[
                const SizedBox(height: 16),
                _Section(
                  title: '章节（${item.chapters.length}）',
                  children: [
                    for (var i = 0;
                        i < item.chapters.length && i < 20;
                        i++)
                      _Row(
                        label: _formatDuration(item.chapters[i].startMs),
                        value: item.chapters[i].title.trim().isEmpty
                            ? '第${i + 1}章'
                            : item.chapters[i].title.trim(),
                      ),
                    if (item.chapters.length > 20)
                      _Row(
                        label: '…',
                        value: '共 ${item.chapters.length} 章',
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _libraryBreadcrumb(LibraryService library, VideoItem item) {
    final parts = <String>[];
    var parentId = item.parentId;
    while (parentId != null) {
      final col = library.getCollection(parentId);
      if (col == null) break;
      parts.add(col.name);
      parentId = col.parentId;
    }
    final folderPath = parts.reversed.join(' / ');
    final leaf = item.effectiveDisplayName;
    if (folderPath.isEmpty) {
      return '媒体库 / $leaf';
    }
    return '媒体库 / $folderPath / $leaf';
  }

  static String _subtitleOverview(VideoItem item) {
    final parts = <String>[];
    if (item.subtitlePath != null && item.subtitlePath!.isNotEmpty) {
      parts.add('有主字幕');
    }
    final managed = item.managedSubtitleAssets.length;
    if (managed > 0) parts.add('托管 $managed');
    final local = item.localSubtitleGroups.length;
    if (local > 0) parts.add('本地组 $local');
    final download = item.downloadAssociatedSubtitles.length;
    if (download > 0) parts.add('下载关联 $download');
    if (item.danmakuPath != null) parts.add('弹幕');
    if (parts.isEmpty) return '无字幕';
    return parts.join(' · ');
  }

  static String _formatProgress(VideoItem item) {
    if (item.durationMs <= 0) {
      return item.lastPositionMs > 0
          ? _formatDuration(item.lastPositionMs)
          : '未开始';
    }
    final pct =
        (item.lastPositionMs / item.durationMs * 100).clamp(0, 100);
    return '${_formatDuration(item.lastPositionMs)} / ${_formatDuration(item.durationMs)} (${pct.toStringAsFixed(0)}%)';
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

  static String _formatEpoch(int? ms) {
    if (ms == null || ms <= 0) return '—';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  static String _formatBitRate(int bitRate) {
    if (bitRate >= 1000000) {
      return '${(bitRate / 1000000).toStringAsFixed(2)} Mbps';
    }
    if (bitRate >= 1000) {
      return '${(bitRate / 1000).toStringAsFixed(0)} kbps';
    }
    return '$bitRate bps';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: AppRadii.borderMd,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 13,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
