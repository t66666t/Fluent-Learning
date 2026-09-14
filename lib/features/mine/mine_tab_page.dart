import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/core/theme_tokens.dart';
import 'package:fluent_learning/features/centers/download_center_page.dart';
import 'package:fluent_learning/features/centers/model_center_page.dart';
import 'package:fluent_learning/features/centers/processing_center_page.dart';
import 'package:fluent_learning/services/settings_service.dart';
import 'package:fluent_learning/system/download_center/download_center.dart';
import 'package:fluent_learning/widgets/media_library_settings_sheet.dart';

/// 「我的」Tab — Phase 9 settings navigation shell.
///
/// Links/opens existing settings UI without rewriting settings logic.
class MineTabPage extends StatelessWidget {
  const MineTabPage({super.key});

  void _openMediaLibrarySettings(BuildContext context) {
    final settings = context.read<SettingsService>();
    showMediaLibrarySettingsBottomSheet(context, settings);
  }

  void _openRoute(
    BuildContext context, {
    required Widget page,
    required String name,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => page,
        settings: RouteSettings(name: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const _SectionLabel('设置'),
          const SizedBox(height: 8),
          _NavCard(
            icon: Icons.settings_outlined,
            iconColor: Colors.lightBlueAccent,
            title: '媒体库设置',
            subtitle: '导入副本、缓存与库相关选项',
            onTap: () => _openMediaLibrarySettings(context),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('中心入口'),
          const SizedBox(height: 8),
          _NavCard(
            icon: Icons.cloud_download_outlined,
            iconColor: const Color(0xFFFB7299),
            title: '下载中心',
            subtitle: 'B站 / yt-dlp 下载入口',
            onTap: () => _openRoute(
              context,
              page: const DownloadCenterPage(),
              name: DownloadCenterRoutes.hall,
            ),
          ),
          const SizedBox(height: 10),
          _NavCard(
            icon: Icons.auto_awesome_outlined,
            iconColor: Colors.tealAccent,
            title: '处理中心',
            subtitle: '转录与处理任务队列',
            onTap: () => _openRoute(
              context,
              page: const ProcessingCenterPage(),
              name: '/processing_center',
            ),
          ),
          const SizedBox(height: 10),
          _NavCard(
            icon: Icons.smart_toy_outlined,
            iconColor: Colors.amberAccent,
            title: '模型中心',
            subtitle: '转录 / 翻译等模型选择',
            onTap: () => _openRoute(
              context,
              page: const ModelCenterPage(),
              name: '/model_center',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '播放器内设置仍从播放页打开；此处仅做导航壳，不重写设置逻辑。',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
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
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        borderRadius: AppRadii.borderLg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withValues(alpha: 0.18),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
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
