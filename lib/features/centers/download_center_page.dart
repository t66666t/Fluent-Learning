import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/features/youtube_download/presentation/pages/yt_dlp_download_screen.dart';
import 'package:fluent_learning/features/youtube_download/services/yt_dlp_download_service.dart';
import 'package:fluent_learning/screens/bilibili_download_screen.dart';
import 'package:fluent_learning/services/bilibili/bilibili_download_service.dart';
import 'package:fluent_learning/system/download_center/download_center.dart';
import 'package:fluent_learning/system/feedback/feedback.dart';
import 'package:fluent_learning/app/responsive.dart';
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

  @override
  Widget build(BuildContext context) {
    final listPad = context.isCompact
        ? const EdgeInsets.fromLTRB(12, 12, 12, 20)
        : context.isExpanded
            ? const EdgeInsets.fromLTRB(24, 20, 24, 32)
            : const EdgeInsets.all(16);
    final cardGap = context.isCompact ? 8.0 : (context.isExpanded ? 14.0 : 12.0);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('下载中心'),
        backgroundColor: AppColors.elevated,
        elevation: 0,
      ),
      body: Consumer2<BilibiliDownloadService, YtDlpDownloadService>(
        builder: (context, bilibili, ytDlp, _) {
          final biliInProgress =
              DownloadCenterQueueSummary.countBilibiliInProgress(bilibili);
          final ytInProgress =
              DownloadCenterQueueSummary.countYtDlpInProgress(ytDlp);
          final totalInProgress = biliInProgress + ytInProgress;

          final feedback = buildInlineFeedbackBanner(dense: true);
          final summarySurface = Color.alphaBlend(
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.elevated,
          );
          return ListView(
            padding: listPad,
            children: [
              if (feedback != null) ...[
                feedback,
                SizedBox(height: cardGap),
              ],
              Material(
                color: summarySurface,
                borderRadius: AppRadii.borderLg,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_download_outlined,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          totalInProgress == 0
                              ? '当前无进行中的下载'
                              : '进行中 $totalInProgress（B站 $biliInProgress · yt-dlp $ytInProgress）',
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: cardGap + 4),
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
              SizedBox(height: cardGap),
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
    final pad = context.isCompact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 14)
        : context.isExpanded
            ? const EdgeInsets.symmetric(horizontal: 18, vertical: 20)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 18);
    return Material(
      color: AppColors.elevated,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        borderRadius: AppRadii.borderLg,
        hoverColor: AppColors.onSurface.withValues(alpha: 0.06),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        onTap: onTap,
        child: Padding(
          padding: pad,
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
                          color: AppColors.error,
                          borderRadius: AppRadii.borderSm,
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: AppColors.onError,
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
                        color: AppColors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
