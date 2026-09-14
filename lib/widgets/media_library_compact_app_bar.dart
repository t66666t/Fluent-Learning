import 'package:flutter/material.dart';

import 'package:fluent_learning/core/theme_tokens.dart';

const double mediaLibraryCompactTopBarBreakpoint = AppBreakpoints.compact;

bool useCompactMediaLibraryTopBar(BuildContext context) {
  return MediaQuery.sizeOf(context).width < mediaLibraryCompactTopBarBreakpoint;
}

const TextStyle mediaLibraryCompactTitleStyle = TextStyle(
  fontFamily: 'Noto Sans SC',
  fontSize: 16,
  height: 1.2,
  // Match the media-library title weight used by the regular tablet/desktop
  // theme while retaining the compact phone size and spacing.
  fontWeight: FontWeight.w300,
  letterSpacing: -0.15,
  color: AppColors.onSurface,
);
const double mediaLibraryCompactTitleOpticalOffset = -1;

/// Noto Sans SC's visual glyph center sits slightly below its line box center.
/// This optical correction aligns compact titles with adjacent toolbar icons
/// without changing layout or touch-target geometry.
class MediaLibraryCompactTitle extends StatelessWidget {
  const MediaLibraryCompactTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, mediaLibraryCompactTitleOpticalOffset),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: mediaLibraryCompactTitleStyle,
      ),
    );
  }
}

class MediaLibraryCompactIconButton extends StatelessWidget {
  const MediaLibraryCompactIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, color: color ?? AppColors.onSurface),
      iconSize: 21,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 40, height: 48),
      splashRadius: 20,
      style: IconButton.styleFrom(
        hoverColor: AppColors.onSurface.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.12),
      ),
    );
  }
}

class MediaLibraryCompactMoreButton extends StatelessWidget {
  const MediaLibraryCompactMoreButton({super.key, required this.itemBuilder});

  final PopupMenuItemBuilder<VoidCallback> itemBuilder;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      tooltip: '更多',
      icon: const Icon(Icons.more_horiz_rounded, color: AppColors.onSurface),
      iconSize: 22,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 176),
      color: AppColors.elevated,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
      onSelected: (action) => action(),
      itemBuilder: itemBuilder,
    );
  }
}

PopupMenuItem<VoidCallback> mediaLibraryCompactMenuItem({
  required IconData icon,
  required String label,
  required VoidCallback onSelected,
  Color? color,
}) {
  final itemColor = color ?? AppColors.onSurface;
  return PopupMenuItem<VoidCallback>(
    value: onSelected,
    height: 44,
    child: Row(
      children: [
        Icon(icon, size: 20, color: itemColor),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Noto Sans SC',
            fontSize: 14,
            color: itemColor,
          ),
        ),
      ],
    ),
  );
}
