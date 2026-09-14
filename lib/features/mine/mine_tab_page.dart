import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/app/responsive.dart';
import 'package:fluent_learning/core/theme_tokens.dart';
import 'package:fluent_learning/domain/sync/sync.dart';
import 'package:fluent_learning/features/centers/download_center_page.dart';
import 'package:fluent_learning/features/centers/model_center_page.dart';
import 'package:fluent_learning/features/centers/processing_center_page.dart';
import 'package:fluent_learning/features/learning_unit/data/learning_unit_repository.dart';
import 'package:fluent_learning/services/library_service.dart';
import 'package:fluent_learning/services/settings_service.dart';
import 'package:fluent_learning/system/download_center/download_center.dart';
import 'package:fluent_learning/system/feedback/feedback.dart';
import 'package:fluent_learning/widgets/media_library_settings_sheet.dart';

/// 「我的」Tab — settings navigation + Phase 12 metadata export/import.
class MineTabPage extends StatefulWidget {
  const MineTabPage({super.key});

  @override
  State<MineTabPage> createState() => _MineTabPageState();
}

class _MineTabPageState extends State<MineTabPage> with AppInlineFeedbackMixin {
  bool _busy = false;

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

  Future<void> _exportMetadata() async {
    if (_busy) return;
    setState(() => _busy = true);
    showInlineFeedback(
      AppFeedbackMessage.loading('正在导出元数据…'),
      autoClear: false,
    );
    try {
      final units = context.read<LearningUnitRepository>().allUnitsForSync;
      final media = context.read<LibraryService>().videosForSyncMetadata;
      final file = await MetadataSyncIo.writeExportFile(
        learningUnits: units,
        mediaItems: media,
      );
      if (!mounted) return;
      await MetadataSyncIo.shareExportFile(file);
      if (!mounted) return;
      showInlineFeedback(
        AppFeedbackMessage.success(
          '已导出 ${units.length} 个学习单元（元数据，不含视频）\n${file.path}',
          title: '导出成功',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showInlineFeedback(
        AppFeedbackMessage.error('导出失败: $e', title: '导出'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importMetadata() async {
    if (_busy) return;
    setState(() => _busy = true);
    showInlineFeedback(
      AppFeedbackMessage.loading('选择并导入元数据…'),
      autoClear: false,
    );
    try {
      final bundle = await MetadataSyncIo.pickAndDecodeBundle();
      if (!mounted) return;
      if (bundle == null) {
        clearInlineFeedback();
        return;
      }
      final repo = context.read<LearningUnitRepository>();
      final result = await MetadataSyncIo.importBundleIntoRepository(
        repository: repo,
        bundle: bundle,
      );
      if (!mounted) return;
      showInlineFeedback(
        AppFeedbackMessage.success(
          '导入学习单元 ${result.upserted}，跳过 ${result.skipped}'
          '${result.mediaRows > 0 ? '；媒体元数据行 ${result.mediaRows}（仅记录，未改库文件）' : ''}',
          title: '导入完成',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showInlineFeedback(
        AppFeedbackMessage.error('导入失败: $e', title: '导入'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedback = buildInlineFeedbackBanner(dense: true);
    final spacing = _MineSpacing.of(context);
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: AppColors.elevated,
        elevation: 0,
      ),
      body: ListView(
        padding: spacing.listPadding,
        children: [
          if (feedback != null) ...[
            feedback,
            SizedBox(height: spacing.itemGap + 2),
          ],
          const _SectionLabel('设置'),
          SizedBox(height: spacing.labelGap),
          _NavCard(
            metrics: spacing,
            icon: Icons.settings_outlined,
            iconColor: AppColors.primary,
            title: '媒体库设置',
            subtitle: '导入副本、缓存与库相关选项',
            onTap: () => _openMediaLibrarySettings(context),
          ),
          SizedBox(height: spacing.sectionGap),
          const _SectionLabel('中心入口'),
          SizedBox(height: spacing.labelGap),
          _NavCard(
            metrics: spacing,
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
          SizedBox(height: spacing.itemGap),
          _NavCard(
            metrics: spacing,
            icon: Icons.auto_awesome_outlined,
            iconColor: AppColors.success,
            title: '处理中心',
            subtitle: '批量字幕 / OCR / 合成 / 转录队列',
            onTap: () => _openRoute(
              context,
              page: const ProcessingCenterPage(),
              name: '/processing_center',
            ),
          ),
          SizedBox(height: spacing.itemGap),
          _NavCard(
            metrics: spacing,
            icon: Icons.smart_toy_outlined,
            iconColor: AppColors.warning,
            title: '模型中心',
            subtitle: '转录 / 翻译等模型选择',
            onTap: () => _openRoute(
              context,
              page: const ModelCenterPage(),
              name: '/model_center',
            ),
          ),
          SizedBox(height: spacing.sectionGap),
          const _SectionLabel('数据与同步（元数据）'),
          SizedBox(height: spacing.labelGap),
          _NavCard(
            metrics: spacing,
            icon: Icons.upload_file_outlined,
            iconColor: AppColors.success,
            title: '导出学习元数据',
            subtitle: 'JSON 导出学习单元 + 轻量媒体字段（不含视频文件）',
            onTap: _busy ? () {} : _exportMetadata,
          ),
          SizedBox(height: spacing.itemGap),
          _NavCard(
            metrics: spacing,
            icon: Icons.download_outlined,
            iconColor: AppColors.primary,
            title: '导入学习元数据',
            subtitle: '从 JSON 合并学习单元（按 updatedAt / revision）',
            onTap: _busy ? () {} : _importMetadata,
          ),
          SizedBox(height: spacing.sectionGap + 4),
          Text(
            '播放器内设置仍从播放页打开；导出仅含元数据，不同步视频/音频本体。',
            style: TextStyle(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.75),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MineSpacing {
  const _MineSpacing({
    required this.listPadding,
    required this.sectionGap,
    required this.itemGap,
    required this.labelGap,
    required this.cardPadding,
  });

  final EdgeInsets listPadding;
  final double sectionGap;
  final double itemGap;
  final double labelGap;
  final EdgeInsets cardPadding;

  static _MineSpacing of(BuildContext context) {
    if (context.isCompact) {
      return const _MineSpacing(
        listPadding: EdgeInsets.fromLTRB(12, 12, 12, 28),
        sectionGap: 16,
        itemGap: 8,
        labelGap: 6,
        cardPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
    }
    if (context.isExpanded) {
      return const _MineSpacing(
        listPadding: EdgeInsets.fromLTRB(24, 20, 24, 36),
        sectionGap: 24,
        itemGap: 12,
        labelGap: 10,
        cardPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
    }
    return const _MineSpacing(
      listPadding: EdgeInsets.fromLTRB(16, 16, 16, 32),
      sectionGap: 20,
      itemGap: 10,
      labelGap: 8,
      cardPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        color: AppColors.onSurfaceVariant,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.metrics,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final _MineSpacing metrics;
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
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        borderRadius: AppRadii.borderLg,
        hoverColor: AppColors.onSurface.withValues(alpha: 0.06),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        onTap: onTap,
        child: Padding(
          padding: metrics.cardPadding,
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
                        color: AppColors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
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
