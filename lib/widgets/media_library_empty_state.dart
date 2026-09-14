import 'package:flutter/material.dart';

import 'package:fluent_learning/core/theme_tokens.dart';

/// Shared empty / no-search-results copy for Library & Media Picker (Phase 16).
abstract final class MediaLibraryEmptyCopy {
  static const String libraryEmptyTitle = '还没有内容';
  static const String libraryEmptySubtitle = '导入视频或音频后会出现在这里';

  static const String collectionEmptyTitle = '合集是空的';
  static const String collectionEmptySubtitle = '添加媒体到此合集';

  static const String searchNoResultsTitle = '没有找到匹配项目';
  static const String searchNoResultsSubtitle = '试试其他关键词';

  static const String pickerEmptyTitle = '暂无媒体';
  static const String pickerEmptySubtitle = '请先导入视频或音频';

  static const String pickerFolderEmptyTitle = '此文件夹为空';
  static const String pickerFolderEmptySubtitle = '换个文件夹，或先导入媒体';
}

/// Consistent empty-state presentation (icon + title + optional subtitle).
class MediaLibraryEmptyState extends StatelessWidget {
  const MediaLibraryEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.folder_open,
    this.compact = false,
    this.child,
  });

  /// Library root with no items.
  const MediaLibraryEmptyState.library({super.key, this.child})
      : icon = Icons.folder_open,
        title = MediaLibraryEmptyCopy.libraryEmptyTitle,
        subtitle = MediaLibraryEmptyCopy.libraryEmptySubtitle,
        compact = false;

  /// Collection / folder with no items.
  const MediaLibraryEmptyState.collection({super.key, this.child})
      : icon = Icons.video_collection_outlined,
        title = MediaLibraryEmptyCopy.collectionEmptyTitle,
        subtitle = MediaLibraryEmptyCopy.collectionEmptySubtitle,
        compact = false;

  /// Search returned zero matches (library or picker).
  const MediaLibraryEmptyState.searchNoResults({
    super.key,
    this.compact = false,
  })  : icon = Icons.search_off_rounded,
        title = MediaLibraryEmptyCopy.searchNoResultsTitle,
        subtitle = MediaLibraryEmptyCopy.searchNoResultsSubtitle,
        child = null;

  /// Media picker has no library media at all.
  const MediaLibraryEmptyState.pickerEmpty({super.key})
      : icon = Icons.video_library_outlined,
        title = MediaLibraryEmptyCopy.pickerEmptyTitle,
        subtitle = MediaLibraryEmptyCopy.pickerEmptySubtitle,
        compact = true,
        child = null;

  /// Media picker folder with no children (non-search).
  const MediaLibraryEmptyState.pickerFolderEmpty({super.key})
      : icon = Icons.folder_open,
        title = MediaLibraryEmptyCopy.pickerFolderEmptyTitle,
        subtitle = MediaLibraryEmptyCopy.pickerFolderEmptySubtitle,
        compact = true,
        child = null;

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool compact;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 56.0 : 80.0;
    final titleSize = compact ? 14.0 : 15.0;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: compact ? 16 : 24,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: AppColors.outline),
            SizedBox(height: compact ? 12 : 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: titleSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.75),
                  fontSize: compact ? 12 : 13,
                  height: 1.35,
                ),
              ),
            ],
            if (child != null) ...[
              SizedBox(height: compact ? 12 : 16),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}
