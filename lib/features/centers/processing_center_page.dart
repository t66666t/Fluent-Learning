import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:fluent_learning/app/responsive.dart';
import 'package:fluent_learning/core/theme_tokens.dart';
import 'package:fluent_learning/features/centers/ocr_subtitle_entry_page.dart';
import 'package:fluent_learning/features/centers/video_compose_entry_page.dart';
import 'package:fluent_learning/screens/batch_subtitle_screen.dart';
import 'package:fluent_learning/services/library_service.dart';
import 'package:fluent_learning/services/playback_navigation_service.dart';
import 'package:fluent_learning/system/feedback/feedback.dart';
import 'package:fluent_learning/system/processing_center/processing_center.dart';

/// Processing Center — capability entries + live queue from TranscriptionManager.
class ProcessingCenterPage extends StatefulWidget {
  const ProcessingCenterPage({super.key, this.collectionId});

  final String? collectionId;

  @override
  State<ProcessingCenterPage> createState() => _ProcessingCenterPageState();
}

class _ProcessingCenterPageState extends State<ProcessingCenterPage>
    with AppInlineFeedbackMixin {
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
      BatchSubtitleScreen(collectionId: widget.collectionId),
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

  void _retryJob(ProcessingCenter center, ProcessingJobView job) {
    final ok = center.retryJob(job.id);
    showInlineFeedback(
      ok
          ? AppFeedbackMessage.success('已重新入队并开始：${job.title}', title: '重试')
          : AppFeedbackMessage.error('无法重试该任务', title: '重试失败'),
    );
  }

  Future<void> _openSuccessResult(ProcessingJobView job) async {
    final videoId = job.videoId?.trim();
    if (!job.isExternal && videoId != null && videoId.isNotEmpty) {
      final library = context.read<LibraryService>();
      final item = library.getVideo(videoId);
      if (item == null) {
        showInlineFeedback(
          AppFeedbackMessage.error('媒体已不存在或已被删除', title: '无法打开'),
        );
        return;
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        PlaybackNavigationService.buildPlaybackEntryRoute(item),
      );
      return;
    }

    final path = job.videoPath?.trim();
    if (path == null || path.isEmpty) {
      showInlineFeedback(
        AppFeedbackMessage.info('暂无可用结果路径', title: '结果'),
      );
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      if (!mounted) return;
      showInlineFeedback(
        AppFeedbackMessage.error('结果文件已不存在', title: '无法打开'),
      );
      return;
    }

    try {
      if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', ['-R', path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [p.dirname(path)]);
      } else {
        await OpenFilex.open(path);
      }
    } catch (e) {
      if (!mounted) return;
      showInlineFeedback(
        AppFeedbackMessage.error('打开失败：$e', title: '无法打开'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerPad = context.isCompact
        ? const EdgeInsets.fromLTRB(12, 10, 12, 8)
        : context.isExpanded
            ? const EdgeInsets.fromLTRB(24, 16, 24, 10)
            : const EdgeInsets.fromLTRB(16, 12, 16, 8);
    final listHPad = context.isCompact ? 10.0 : (context.isExpanded ? 20.0 : 12.0);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('处理中心'),
        backgroundColor: AppColors.elevated,
        elevation: 0,
      ),
      body: Consumer<ProcessingCenter>(
        builder: (context, center, _) {
          final jobs = center.jobs;
          final feedback = buildInlineFeedbackBanner(dense: true);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: headerPad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (feedback != null) ...[
                      feedback,
                      const SizedBox(height: 10),
                    ],
                    const Text(
                      '能力入口',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CapabilityRow(
                      children: [
                        _CapabilityCard(
                          icon: Icons.subtitles_outlined,
                          iconColor: AppColors.success,
                          title: '批量字幕',
                          subtitle: '转录队列批量入队',
                          onTap: () => _openBatchSubtitle(context),
                        ),
                        _CapabilityCard(
                          icon: Icons.document_scanner_outlined,
                          iconColor: AppColors.warning,
                          title: 'OCR',
                          subtitle: '区域识别生成字幕',
                          onTap: () => _openOcr(context),
                        ),
                        _CapabilityCard(
                          icon: Icons.movie_filter_outlined,
                          iconColor: const Color(0xFFB39DDB),
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
                          color: AppColors.warning,
                        ),
                        _StatChip(
                          label: '进行 ${center.runningCount}',
                          color: AppColors.primary,
                        ),
                        _StatChip(
                          label: '成功 ${center.successCount}',
                          color: AppColors.success,
                        ),
                        _StatChip(
                          label: '失败 ${center.failedCount}',
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.outlineVariant),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  headerPad.left,
                  10,
                  headerPad.right,
                  4,
                ),
                child: Row(
                  children: [
                    const Text(
                      '处理队列',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${jobs.length} 项',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
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
                              color: AppColors.onSurfaceVariant,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: listHPad,
                          vertical: 8,
                        ),
                        itemCount: jobs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final job = jobs[index];
                          return _JobTile(
                            job: job,
                            onRetry: job.phase == ProcessingJobPhase.failed
                                ? () => _retryJob(center, job)
                                : null,
                            onOpenResult:
                                job.phase == ProcessingJobPhase.success
                                    ? () => _openSuccessResult(job)
                                    : null,
                          );
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
      color: AppColors.elevated,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: AppRadii.borderMd,
      child: InkWell(
        borderRadius: AppRadii.borderMd,
        hoverColor: AppColors.onSurface.withValues(alpha: 0.06),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
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
                        color: AppColors.onSurface,
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
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
                size: 18,
              ),
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
  const _JobTile({
    required this.job,
    this.onRetry,
    this.onOpenResult,
  });

  final ProcessingJobView job;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenResult;

  @override
  Widget build(BuildContext context) {
    final phase = job.phase;
    final Color accent;
    final String phaseLabel;
    final IconData icon;
    switch (phase) {
      case ProcessingJobPhase.queued:
        accent = AppColors.warning;
        phaseLabel = '排队';
        icon = Icons.hourglass_empty;
        break;
      case ProcessingJobPhase.running:
        accent = AppColors.primary;
        phaseLabel = '进行中';
        icon = Icons.play_circle_outline;
        break;
      case ProcessingJobPhase.success:
        accent = AppColors.success;
        phaseLabel = '成功';
        icon = Icons.check_circle_outline;
        break;
      case ProcessingJobPhase.failed:
        accent = AppColors.error;
        phaseLabel = '失败';
        icon = Icons.error_outline;
        break;
    }

    return Material(
      color: AppColors.elevated,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: AppRadii.borderMd,
      child: InkWell(
        borderRadius: AppRadii.borderMd,
        hoverColor: AppColors.onSurface.withValues(alpha: 0.06),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        onTap: onOpenResult,
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
                        color: AppColors.onSurface,
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
                  color: AppColors.onSurfaceVariant,
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
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
              if (phase == ProcessingJobPhase.running) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: job.progress > 0 && job.progress <= 1
                        ? job.progress
                        : null,
                    minHeight: 4,
                    backgroundColor: AppColors.outlineVariant,
                    color: accent,
                  ),
                ),
              ],
              if (onRetry != null || onOpenResult != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (onRetry != null)
                      OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('重试'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    if (onOpenResult != null) ...[
                      if (onRetry != null) const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onOpenResult,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('查看结果'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.success,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
