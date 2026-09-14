import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/core/theme_tokens.dart';
import 'package:fluent_learning/features/centers/download_center_page.dart';
import 'package:fluent_learning/features/centers/model_center_page.dart';
import 'package:fluent_learning/features/centers/processing_center_page.dart';
import 'package:fluent_learning/features/youtube_download/services/yt_dlp_download_service.dart';
import 'package:fluent_learning/services/bilibili/bilibili_download_service.dart';
import 'package:fluent_learning/system/download_center/download_center.dart';
import 'package:fluent_learning/system/feedback/feedback.dart';
import 'package:fluent_learning/system/media_picker/media_picker.dart';
import 'package:fluent_learning/system/model_center/model_center.dart';
import 'package:fluent_learning/system/processing_center/processing_center.dart';

/// 「中心」Tab — Centers hall with Model / Download / Processing entries.
class CentersTabPage extends StatefulWidget {
  const CentersTabPage({super.key});

  @override
  State<CentersTabPage> createState() => _CentersTabPageState();
}

class _CentersTabPageState extends State<CentersTabPage>
    with AppInlineFeedbackMixin {
  String _trialPickerSummary = '尚未选片';

  Future<void> _openTrialPicker() async {
    final result = await showAppMediaPicker(
      context,
      const MediaPickerRequest(
        multiSelect: true,
        allowFolders: true,
        title: '试用选片',
        confirmLabel: '选用',
      ),
    );
    if (!mounted) return;
    setState(() {
      if (result == null) {
        _trialPickerSummary = '已取消';
      } else {
        final folders = result.folderIds.isEmpty
            ? ''
            : '，文件夹 ${result.folderIds.length}';
        _trialPickerSummary =
            '已选媒体 ${result.mediaIds.length}$folders';
      }
    });
    showInlineFeedback(
      result == null
          ? AppFeedbackMessage.info('已取消选片', title: '试用选片')
          : AppFeedbackMessage.success(_trialPickerSummary, title: '试用选片'),
    );
  }

  void _open(Widget page, {String? name}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => page,
        settings: name == null ? null : RouteSettings(name: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('中心'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          PopupMenuButton<_CentersMenuAction>(
            tooltip: '更多',
            icon: const Icon(Icons.more_vert, color: Colors.white54),
            color: const Color(0xFF2A2A2A),
            onSelected: (action) {
              if (action == _CentersMenuAction.trialPicker) {
                _openTrialPicker();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _CentersMenuAction.trialPicker,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('试用选片', style: TextStyle(color: Colors.white70)),
                    Text(
                      _trialPickerSummary,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer4<ProcessingCenter, BilibiliDownloadService,
          YtDlpDownloadService, ModelCenter>(
        builder: (context, processing, bilibili, ytDlp, models, _) {
          final biliInProgress =
              DownloadCenterQueueSummary.countBilibiliInProgress(bilibili);
          final ytInProgress =
              DownloadCenterQueueSummary.countYtDlpInProgress(ytDlp);
          final downloadInProgress = biliInProgress + ytInProgress;
          final processingInProgress = processing.inProgressCount;
          final processingFailed = processing.failedCount;
          final activeTranscription = models.resolve(ModelKind.transcription);

          final feedback = buildInlineFeedbackBanner(dense: true);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (feedback != null) ...[
                feedback,
                const SizedBox(height: 12),
              ],
              _HallCard(
                icon: Icons.psychology_outlined,
                iconColor: Colors.purpleAccent,
                title: '模型中心',
                subtitle: '转录 / 翻译 / 问答 模型选择',
                hint: activeTranscription == null
                    ? '转录模型未配置'
                    : '当前转录：${activeTranscription.displayName}',
                onTap: () => _open(
                  const ModelCenterPage(),
                  name: '/model_center',
                ),
              ),
              const SizedBox(height: 12),
              _HallCard(
                icon: Icons.download_outlined,
                iconColor: Colors.lightBlueAccent,
                title: '下载中心',
                subtitle: 'B站下载 · YT-DLP 下载',
                badges: [
                  if (downloadInProgress > 0)
                    _QueueBadge(
                      label: '进行中 $downloadInProgress',
                      color: Colors.lightBlueAccent,
                    ),
                ],
                hint: downloadInProgress > 0
                    ? 'B站 $biliInProgress · yt-dlp $ytInProgress'
                    : null,
                onTap: () => _open(
                  const DownloadCenterPage(),
                  name: '/download_center',
                ),
              ),
              const SizedBox(height: 12),
              _HallCard(
                icon: Icons.tune,
                iconColor: Colors.tealAccent,
                title: '处理中心',
                subtitle: '批量字幕 / OCR / 合成 / 转录队列',
                badges: [
                  if (processingInProgress > 0)
                    _QueueBadge(
                      label: '进行中 $processingInProgress',
                      color: Colors.lightBlueAccent,
                    ),
                  if (processingFailed > 0)
                    _QueueBadge(
                      label: '失败 $processingFailed',
                      color: Colors.redAccent,
                    ),
                ],
                onTap: () => _open(
                  const ProcessingCenterPage(),
                  name: '/processing_center',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _CentersMenuAction { trialPicker }

class _HallCard extends StatelessWidget {
  const _HallCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.hint,
    this.badges = const <_QueueBadge>[],
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? hint;
  final List<_QueueBadge> badges;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withValues(alpha: 0.18),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    if (hint != null && hint!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        hint!,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (badges.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: badges,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueBadge extends StatelessWidget {
  const _QueueBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadii.borderSm,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
