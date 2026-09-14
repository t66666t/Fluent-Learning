import 'package:flutter/material.dart';
import 'package:fluent_learning/screens/batch_subtitle_screen.dart';

/// Processing Center shell — navigates to existing [BatchSubtitleScreen].
class ProcessingCenterPage extends StatelessWidget {
  const ProcessingCenterPage({super.key, this.collectionId});

  final String? collectionId;

  void _openBatchSubtitle(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BatchSubtitleScreen(collectionId: collectionId),
        settings: const RouteSettings(name: '/batch_subtitle'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('处理中心'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Material(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openBatchSubtitle(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(0x3326A69A),
                      child: Icon(Icons.closed_caption, color: Colors.tealAccent),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '批量字幕 / 转录队列',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '打开现有批量字幕生成与后台转录队列',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white38),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '播放页「生成 AI 字幕」会经处理中心门面入队，可在上方队列中查看。',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
