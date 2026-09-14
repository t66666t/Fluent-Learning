import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/core/theme_tokens.dart';
import 'package:fluent_learning/models/video_item.dart';
import 'package:fluent_learning/services/library_service.dart';
import 'package:fluent_learning/system/feedback/feedback.dart';
import 'package:fluent_learning/system/media_picker/media_picker.dart';
import 'package:fluent_learning/widgets/ocr_subtitle_panel.dart';

/// Processing Center secondary entry for OCR.
///
/// Picks a library video, then hosts the existing [OcrSubtitlePanel]
/// without rewriting OCR engine internals.
class OcrSubtitleEntryPage extends StatefulWidget {
  const OcrSubtitleEntryPage({super.key});

  static const routeName = '/processing_center/ocr';

  @override
  State<OcrSubtitleEntryPage> createState() => _OcrSubtitleEntryPageState();
}

class _OcrSubtitleEntryPageState extends State<OcrSubtitleEntryPage>
    with AppInlineFeedbackMixin {
  VideoItem? _item;

  Future<void> _pickMedia() async {
    final result = await showAppMediaPicker(
      context,
      const MediaPickerRequest(
        multiSelect: false,
        allowFolders: false,
        typeFilter: {MediaType.video},
        title: '选择视频以进行 OCR',
        confirmLabel: '开始 OCR',
      ),
    );
    if (!mounted || result == null || result.mediaIds.isEmpty) return;
    final library = context.read<LibraryService>();
    final item = library.getVideo(result.mediaIds.first);
    if (item == null) {
      showInlineFeedback(
        AppFeedbackMessage.error('所选媒体不存在或已删除', title: '无法打开 OCR'),
      );
      return;
    }
    if (item.type == MediaType.audio) {
      showInlineFeedback(
        AppFeedbackMessage.error('OCR 仅支持视频媒体', title: '无法打开 OCR'),
      );
      return;
    }
    clearInlineFeedback();
    setState(() => _item = item);
  }

  void _clearSelection() {
    setState(() => _item = null);
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final banner = buildInlineFeedbackBanner(dense: true);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text(item == null ? 'OCR 字幕' : 'OCR · ${item.effectiveDisplayName}'),
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
                : OcrSubtitlePanel(
                    key: ValueKey('ocr_entry_${item.id}'),
                    videoItem: item,
                    duration: Duration(
                      milliseconds: item.durationMs > 0 ? item.durationMs : 1,
                    ),
                    currentPosition: () => Duration.zero,
                    pauseForRegionSelection: () async => false,
                    restorePlayback: (_) async {},
                    onBack: _clearSelection,
                    onCompleted: (paths) async {
                      if (!mounted) return;
                      showInlineFeedback(
                        AppFeedbackMessage.success(
                          paths.isEmpty
                              ? 'OCR 已完成'
                              : '已生成 ${paths.length} 条字幕轨',
                          title: 'OCR 完成',
                        ),
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
              Icons.document_scanner_outlined,
              size: 48,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            const Text(
              '从媒体库选择视频，框选字幕区域后开始 OCR 识别',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurface, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              '不改动 OCR 引擎；此处仅作为处理中心二级入口',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onPick,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: AppColors.onWarning,
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
