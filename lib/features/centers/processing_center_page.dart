import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/core/theme_tokens.dart';
import 'package:fluent_learning/features/centers/ocr_subtitle_entry_page.dart';
import 'package:fluent_learning/features/centers/video_compose_entry_page.dart';
import 'package:fluent_learning/screens/batch_subtitle_screen.dart';
import 'package:fluent_learning/system/processing_center/processing_center.dart';

/// Processing Center — capability entries + live queue from TranscriptionManager.
class ProcessingCenterPage extends StatelessWidget {
  const ProcessingCenterPage({super.key, this.collectionId});

  final String? collectionId;

  void _open(BuildContext context, Widget page, {required String name}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => page,
        settings: RouteSettings(name: name),
      ),
    );
  }

  void _openBatchSubtitle(BuildContext context) {
    _open(
      context,
      BatchSubtitleScreen(collectionId: collectionId),
      name: '/batch_subtitle',
    );
  }

  void _openOcr(BuildContext context) {
    _open(
      context,
      const OcrSubtitleEntryPage(),
      name: OcrSubtitleEntryPage.routeName,
    );
  }

  void _openCompose(BuildContext context) {
    _open(
      context,
      const VideoComposeEntryPage(),
      name: VideoComposeEntryPage.routeName,
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
      body: Consumer<ProcessingCenter>(
        builder: (context, center, _) {
          final jobs = center.jobs;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '能力入口',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CapabilityRow(
                      children: [
                        _CapabilityCard(
                          icon: Icons.subtitles_outlined,
                          iconColor: Colors.tealAccent,
                          title: '批量字幕',
                          subtitle: '转录队列批量入队',
                          onTap: () => _openBatchSubtitle(context),
                        ),
                        _CapabilityCard(
                          icon: Icons.document_scanner_outlined,
                          iconColor: Colors.orangeAccent,
                          title: 'OCR',
                          subtitle: '区域识别生成字幕',
                          onTap: () => _openOcr(context),
                        ),
                        _CapabilityCard(
                          icon: Icons.movie_filter_outlined,
                          iconColor: Colors.purpleAccent,
                          title: '合成',
                          subtitle: '字幕烧录 / 导出',
                          onTap: () => _openCompose(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
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
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    const Text(
                      '处理队列',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${jobs.length} 项',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: jobs.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            '暂无处理任务\n'
                            '播放页「生成 AI 字幕」或上方「批量字幕」入队后会显示在这里',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: jobs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
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

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: children[i]),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              children[i],
            ],
          ],
        );
      },
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({
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
      borderRadius: AppRadii.borderMd,
      child: InkWell(
        borderRadius: AppRadii.borderMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: iconColor.withValues(alpha: 0.16),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
            ],
          ),
        ),
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
