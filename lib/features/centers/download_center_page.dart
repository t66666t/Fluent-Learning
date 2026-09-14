import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/features/youtube_download/presentation/pages/yt_dlp_download_screen.dart';
import 'package:fluent_learning/features/youtube_download/services/yt_dlp_download_service.dart';
import 'package:fluent_learning/models/bilibili_download_task.dart';
import 'package:fluent_learning/screens/bilibili_download_screen.dart';
import 'package:fluent_learning/services/bilibili/bilibili_download_service.dart';
import 'package:fluent_learning/system/download_center/download_center.dart';
import 'package:fluent_learning/system/feedback/feedback.dart';
import 'package:fluent_learning/core/theme_tokens.dart';

/// Download Center hall — entry cards to existing B站 / yt-dlp screens.
class DownloadCenterPage extends StatefulWidget {
  const DownloadCenterPage({
    super.key,
    this.targetFolderId,
    this.initialBilibiliInput,
    this.openBilibiliOnLaunch = false,
    this.initialStreamingMode = false,
  });

  final String? targetFolderId;
  final String? initialBilibiliInput;
  final bool openBilibiliOnLaunch;
  final bool initialStreamingMode;

  @override
  State<DownloadCenterPage> createState() => _DownloadCenterPageState();
}

class _DownloadCenterPageState extends State<DownloadCenterPage>
    with AppInlineFeedbackMixin {
  @override
  void initState() {
    super.initState();
    if (widget.openBilibiliOnLaunch ||
        widget.initialStreamingMode ||
        (widget.initialBilibiliInput != null &&
            widget.initialBilibiliInput!.trim().isNotEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openBilibili(streamingMode: widget.initialStreamingMode);
      });
    }
  }

  void _openBilibili({bool streamingMode = false}) {
    showInlineFeedback(
      AppFeedback.downloadStarted(
        streamingMode ? '正在打开 B站串流导入…' : '正在打开 B站下载…',
      ),
      hold: AppMotion.emphasized,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BilibiliDownloadScreen(
          initialInput: widget.initialBilibiliInput,
          targetFolderId: widget.targetFolderId,
          initialStreamingMode: streamingMode,
        ),
        settings: RouteSettings(
          name: streamingMode
              ? '/bilibili_stream_import'
              : DownloadCenterRoutes.bilibili,
        ),
      ),
    );
  }

  void _openYtDlp() {
    showInlineFeedback(
      AppFeedback.downloadStarted('正在打开 yt-dlp 下载…'),
      hold: AppMotion.emphasized,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => YtDlpDownloadScreen(
          targetFolderId: widget.targetFolderId,
        ),
        settings: const RouteSettings(name: DownloadCenterRoutes.ytDlp),
      ),
    );
  }

  static int _countBilibiliInProgress(BilibiliDownloadService service) {
    var count = 0;
    for (final task in service.tasks) {
      for (final video in task.videos) {
        for (final ep in video.episodes) {
          switch (ep.status) {
            case DownloadStatus.queued:
            case DownloadStatus.fetchingInfo:
            case DownloadStatus.downloading:
            case DownloadStatus.merging:
            case DownloadStatus.checking:
            case DownloadStatus.repairing:
              count++;
              break;
            case DownloadStatus.pending:
            case DownloadStatus.completed:
            case DownloadStatus.failed:
              break;
          }
        }
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('下载中心'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: Consumer2<BilibiliDownloadService, YtDlpDownloadService>(
        builder: (context, bilibili, ytDlp, _) {
          final biliInProgress = _countBilibiliInProgress(bilibili);
          final ytInProgress = ytDlp.activeCount + ytDlp.queuedCount;
          final totalInProgress = biliInProgress + ytInProgress;

          final feedback = buildInlineFeedbackBanner(dense: true);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (feedback != null) ...[
                feedback,
                const SizedBox(height: 12),
              ],
              Material(
                color: const Color(0xFF1A2330),
                borderRadius: AppRadii.borderLg,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_download_outlined,
                          color: Colors.lightBlueAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          totalInProgress == 0
                              ? '当前无进行中的下载'
                              : '进行中 $totalInProgress（B站 $biliInProgress · yt-dlp $ytInProgress）',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _CenterEntryCard(
                icon: Icons.tv,
                iconColor: const Color(0xFFFB7299),
                title: 'B站下载',
                subtitle: biliInProgress > 0
                    ? '进行中 $biliInProgress · 解析与下载'
                    : 'Bilibili 视频解析与下载',
                badge: biliInProgress > 0 ? '$biliInProgress' : null,
                onTap: () => _openBilibili(),
              ),
              const SizedBox(height: 12),
              _CenterEntryCard(
                icon: Icons.ondemand_video,
                iconColor: const Color(0xFFFF4040),
                title: 'YT-DLP 下载',
                subtitle: ytInProgress > 0
                    ? '进行中 $ytInProgress · YouTube 及其他站点'
                    : 'YouTube 及其他站点（yt-dlp）',
                badge: ytInProgress > 0 ? '$ytInProgress' : null,
                onTap: _openYtDlp,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CenterEntryCard extends StatelessWidget {
  const _CenterEntryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E1E1E),
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        borderRadius: AppRadii.borderLg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    backgroundColor: iconColor.withValues(alpha: 0.18),
                    child: Icon(icon, color: iconColor),
                  ),
                  if (badge != null)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: AppRadii.borderSm,
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
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
