import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/app/responsive.dart';
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

  EdgeInsets _listPadding(BuildContext context) {
    if (context.isCompact) {
      return const EdgeInsets.fromLTRB(12, 12, 12, 20);
    }
    if (context.isExpanded) {
      return const EdgeInsets.fromLTRB(24, 20, 24, 32);
    }
    return const EdgeInsets.fromLTRB(16, 16, 16, 24);
  }

  double _cardGap(BuildContext context) {
    if (context.isCompact) return 8;
    if (context.isExpanded) return 14;
    return 12;
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _HallCardMetrics.of(context);
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('中心'),
        backgroundColor: AppColors.elevated,
        elevation: 0,
        actions: [
          PopupMenuButton<_CentersMenuAction>(
            tooltip: '更多',
            icon: const Icon(Icons.more_vert, color: AppColors.onSurfaceVariant),
            color: AppColors.surfaceContainer,
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
                    const Text(
                      '试用选片',
                      style: TextStyle(color: AppColors.onSurface),
                    ),
                    Text(
                      _trialPickerSummary,
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
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
          final gap = _cardGap(context);

          return _FadeSlideIn(
            child: ListView(
              padding: _listPadding(context),
              children: [
                if (feedback != null) ...[
                  feedback,
                  SizedBox(height: gap),
                ],
                _HallCard(
                  metrics: metrics,
                  icon: Icons.psychology_outlined,
                  iconColor: const Color(0xFFB39DDB),
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
                SizedBox(height: gap),
                _HallCard(
                  metrics: metrics,
                  icon: Icons.download_outlined,
                  iconColor: AppColors.primary,
                  title: '下载中心',
                  subtitle: 'B站下载 · YT-DLP 下载',
                  badges: [
                    if (downloadInProgress > 0)
                      _QueueBadge(
                        label: '进行中 $downloadInProgress',
                        color: AppColors.primary,
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
                SizedBox(height: gap),
                _HallCard(
                  metrics: metrics,
                  icon: Icons.tune,
                  iconColor: AppColors.success,
                  title: '处理中心',
                  subtitle: '批量字幕 / OCR / 合成 / 转录队列',
                  badges: [
                    if (processingInProgress > 0)
                      _QueueBadge(
                        label: '进行中 $processingInProgress',
                        color: AppColors.primary,
                      ),
                    if (processingFailed > 0)
                      _QueueBadge(
                        label: '失败 $processingFailed',
                        color: AppColors.error,
                      ),
                  ],
                  onTap: () => _open(
                    const ProcessingCenterPage(),
                    name: '/processing_center',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _CentersMenuAction { trialPicker }

class _HallCardMetrics {
  const _HallCardMetrics({
    required this.padding,
    required this.iconRadius,
  });

  final EdgeInsets padding;
  final double iconRadius;

  static _HallCardMetrics of(BuildContext context) {
    if (context.isCompact) {
      return const _HallCardMetrics(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        iconRadius: 18,
      );
    }
    if (context.isExpanded) {
      return const _HallCardMetrics(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        iconRadius: 22,
      );
    }
    return const _HallCardMetrics(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      iconRadius: 20,
    );
  }
}

/// One-shot fade + slide enter (≤ [AppMotion.emphasized]).
class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({required this.child});

  final Widget child;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.emphasized,
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.standard,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.04),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.standard));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class _HallCard extends StatelessWidget {
  const _HallCard({
    required this.metrics,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.hint,
    this.badges = const <_QueueBadge>[],
  });

  final _HallCardMetrics metrics;
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
          padding: metrics.padding,
          child: Row(
            children: [
              CircleAvatar(
                radius: metrics.iconRadius,
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
                    if (hint != null && hint!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        hint!,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.75,
                          ),
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
              const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
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
