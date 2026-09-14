import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:fluent_learning/core/theme_tokens.dart';
import 'package:fluent_learning/models/video_item.dart';
import 'package:fluent_learning/services/library_service.dart';
import 'package:fluent_learning/system/feedback/feedback.dart';
import 'package:fluent_learning/system/media_picker/media_picker.dart';
import 'package:fluent_learning/widgets/video_compose_panel.dart';

/// Processing Center secondary entry for video compose.
///
/// Picks a library video, then hosts the existing [VideoComposePanel]
/// without rewriting compose engine internals.
class VideoComposeEntryPage extends StatefulWidget {
  const VideoComposeEntryPage({super.key});

  static const routeName = '/processing_center/video_compose';

  @override
  State<VideoComposeEntryPage> createState() => _VideoComposeEntryPageState();
}

class _VideoComposeEntryPageState extends State<VideoComposeEntryPage>
    with AppInlineFeedbackMixin {
  VideoItem? _item;

  Future<void> _pickMedia() async {
    final result = await showAppMediaPicker(
      context,
      const MediaPickerRequest(
        multiSelect: false,
        allowFolders: false,
        typeFilter: {MediaType.video},
        title: '选择视频以进行合成',
        confirmLabel: '打开合成',
      ),
    );
    if (!mounted || result == null || result.mediaIds.isEmpty) return;
    final library = context.read<LibraryService>();
    final item = library.getVideo(result.mediaIds.first);
    if (item == null) {
      showInlineFeedback(
        AppFeedbackMessage.error('所选媒体不存在或已删除', title: '无法打开合成'),
      );
      return;
    }
    clearInlineFeedback();
    setState(() => _item = item);
  }

  void _clearSelection() {
    setState(() => _item = null);
  }

  Map<String, String> _subtitleMapFor(VideoItem item) {
    final map = <String, String>{};
    final additional = <String, String>{
      ...item.downloadAssociatedSubtitles,
      ...item.localSubtitleGroups,
    };

    String fallbackName(String path, String fallback) {
      final base = p.basenameWithoutExtension(path).trim();
      return base.isNotEmpty ? base : fallback;
    }

    final primary = item.subtitlePath;
    if (primary != null && primary.isNotEmpty) {
      map[primary] = '主字幕（${fallbackName(primary, '主字幕')}）';
    }
    final secondary = item.secondarySubtitlePath;
    if (secondary != null && secondary.isNotEmpty) {
      map[secondary] = '副字幕（${fallbackName(secondary, '副字幕')}）';
    }
    for (final entry in additional.entries) {
      if (entry.value.isEmpty) continue;
      map.putIfAbsent(entry.value, () => entry.key);
    }
    return map;
  }

  List<String> _selectedPathsFor(VideoItem item, Map<String, String> map) {
    final paths = <String>[];
    final primary = item.subtitlePath;
    if (primary != null && primary.isNotEmpty && map.containsKey(primary)) {
      paths.add(primary);
    }
    final secondary = item.secondarySubtitlePath;
    if (secondary != null &&
        secondary.isNotEmpty &&
        map.containsKey(secondary)) {
      paths.add(secondary);
    }
    if (paths.isEmpty && map.isNotEmpty) {
      paths.add(map.keys.first);
    }
    return paths;
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final banner = buildInlineFeedbackBanner(dense: true);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text(item == null ? '视频合成' : '合成 · ${item.effectiveDisplayName}'),
        backgroundColor: AppColors.elevated,
        elevation: 0,
        actions: [
          if (item != null)
            TextButton(
              onPressed: _pickMedia,
              child: const Text('换片'),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (banner != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: banner,
            ),
          Expanded(
            child: item == null
                ? _EmptyPicker(onPick: _pickMedia)
                : Builder(
                    builder: (context) {
                      final map = _subtitleMapFor(item);
                      return VideoComposePanel(
                        key: ValueKey('compose_entry_${item.id}'),
                        videoItem: item,
                        currentSelectedPaths: _selectedPathsFor(item, map),
                        availableSubtitleMap: map,
                        onBack: _clearSelection,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPicker extends StatelessWidget {
  const _EmptyPicker({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_filter_outlined,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              '从媒体库选择视频，配置字幕轨后导出合成成品',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurface, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              '不改动合成引擎；此处仅作为处理中心二级入口',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onPick,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.borderMd,
                ),
              ),
              icon: const Icon(Icons.video_library_outlined),
              label: const Text('选择视频'),
            ),
          ],
        ),
      ),
    );
  }
}
