import 'package:flutter/material.dart';
import 'package:fluent_learning/features/youtube_download/presentation/pages/yt_dlp_download_screen.dart';
import 'package:fluent_learning/screens/bilibili_download_screen.dart';
import 'package:fluent_learning/system/download_center/download_center.dart';

/// Download Center hall — entry cards to existing B站 / yt-dlp screens.
class DownloadCenterPage extends StatefulWidget {
  const DownloadCenterPage({
    super.key,
    this.targetFolderId,
    this.initialBilibiliInput,
    this.openBilibiliOnLaunch = false,
  });

  final String? targetFolderId;
  final String? initialBilibiliInput;
  final bool openBilibiliOnLaunch;

  @override
  State<DownloadCenterPage> createState() => _DownloadCenterPageState();
}

class _DownloadCenterPageState extends State<DownloadCenterPage> {
  @override
  void initState() {
    super.initState();
    if (widget.openBilibiliOnLaunch ||
        (widget.initialBilibiliInput != null &&
            widget.initialBilibiliInput!.trim().isNotEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openBilibili();
      });
    }
  }

  void _openBilibili() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BilibiliDownloadScreen(
          initialInput: widget.initialBilibiliInput,
          targetFolderId: widget.targetFolderId,
        ),
        settings: const RouteSettings(name: DownloadCenterRoutes.bilibili),
      ),
    );
  }

  void _openYtDlp() {
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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('下载中心'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CenterEntryCard(
            icon: Icons.tv,
            iconColor: const Color(0xFFFB7299),
            title: 'B站下载',
            subtitle: 'Bilibili 视频解析与下载',
            onTap: _openBilibili,
          ),
          const SizedBox(height: 12),
          _CenterEntryCard(
            icon: Icons.ondemand_video,
            iconColor: const Color(0xFFFF4040),
            title: 'YT-DLP 下载',
            subtitle: 'YouTube 及其他站点（yt-dlp）',
            onTap: _openYtDlp,
          ),
        ],
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
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
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
