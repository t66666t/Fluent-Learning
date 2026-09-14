import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/screens/batch_subtitle_screen.dart';
import 'package:fluent_learning/system/processing_center/processing_center.dart';
import 'package:fluent_learning/core/theme_tokens.dart';

/// Processing Center — live queue list mirrored from TranscriptionManager.
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
        actions: [
          TextButton(
            onPressed: () => _openBatchSubtitle(context),
            child: const Text('批量字幕'),
          ),
        ],
      ),
      body: Consumer<ProcessingCenter>(
        builder: (context, center, _) {
          final jobs = center.jobs;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(
                      label: '排队 ${center.queuedCount}',
                      color: Colors.orangeAccent,
                    ),
                    _StatChip(
                      label: '进行 ${center.runningCount}',
                      color: Colors.lightBlueAccent,
                    ),
                    _StatChip(
                      label: '成功 ${center.successCount}',
                      color: Colors.tealAccent,
                    ),
                    _StatChip(
                      label: '失败 ${center.failedCount}',
                      color: Colors.redAccent,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              Expanded(
                child: jobs.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            '暂无处理任务\n播放页「生成 AI 字幕」入队后会显示在这里',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: jobs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _JobTile(job: jobs[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadii.borderSm,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job});

  final ProcessingJobView job;

  @override
  Widget build(BuildContext context) {
    final phase = job.phase;
    final Color accent;
    final String phaseLabel;
    final IconData icon;
    switch (phase) {
      case ProcessingJobPhase.queued:
        accent = Colors.orangeAccent;
        phaseLabel = '排队';
        icon = Icons.hourglass_empty;
        break;
      case ProcessingJobPhase.running:
        accent = Colors.lightBlueAccent;
        phaseLabel = '进行中';
        icon = Icons.play_circle_outline;
        break;
      case ProcessingJobPhase.success:
        accent = Colors.tealAccent;
        phaseLabel = '成功';
        icon = Icons.check_circle_outline;
        break;
      case ProcessingJobPhase.failed:
        accent = Colors.redAccent;
        phaseLabel = '失败';
        icon = Icons.error_outline;
        break;
    }

    return Material(
      color: const Color(0xFF1E1E1E),
      borderRadius: AppRadii.borderMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadii.sm - 2),
                  ),
                  child: Text(
                    phaseLabel,
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'ID  ${job.id}',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            if (job.message.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                job.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            if (phase == ProcessingJobPhase.running) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: job.progress > 0 && job.progress <= 1
                      ? job.progress
                      : null,
                  minHeight: 4,
                  backgroundColor: Colors.white12,
                  color: accent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
