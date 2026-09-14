import 'package:flutter/material.dart';

import 'package:fluent_learning/features/centers/download_center_page.dart';
import 'package:fluent_learning/features/centers/model_center_page.dart';
import 'package:fluent_learning/features/centers/processing_center_page.dart';
import 'package:fluent_learning/system/media_picker/media_picker.dart';

/// 「中心」Tab — Centers hall with Model / Download / Processing entries.
class CentersTabPage extends StatefulWidget {
  const CentersTabPage({super.key});

  @override
  State<CentersTabPage> createState() => _CentersTabPageState();
}

class _CentersTabPageState extends State<CentersTabPage> {
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HallCard(
            icon: Icons.psychology_outlined,
            iconColor: Colors.purpleAccent,
            title: '模型中心',
            subtitle: '转录 / 翻译 / 问答 模型选择',
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
            subtitle: '批量字幕 / 转录队列',
            onTap: () => _open(
              const ProcessingCenterPage(),
              name: '/processing_center',
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            '工具',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _openTrialPicker,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.video_library_outlined,
                        color: Colors.white70),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '试用选片',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _trialPickerSummary,
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
          ),
        ],
      ),
    );
  }
}

class _HallCard extends StatelessWidget {
  const _HallCard({
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
