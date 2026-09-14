/// Responsive layout helpers (beautify U1).
///
/// UI-only width breakpoints based on [AppBreakpoints].
library;

import 'package:flutter/widgets.dart';

import 'package:fluent_learning/core/theme_tokens.dart';

/// Coarse layout band derived from [MediaQuery] width.
enum AppBreakpoint {
  compact,
  medium,
  expanded,
}

extension AppResponsiveContext on BuildContext {
  /// Current breakpoint from [MediaQuery] size width.
  AppBreakpoint get breakpoint {
    final width = MediaQuery.sizeOf(this).width;
    if (width < AppBreakpoints.compact) return AppBreakpoint.compact;
    if (width < AppBreakpoints.expanded) return AppBreakpoint.medium;
    return AppBreakpoint.expanded;
  }

  bool get isCompact => breakpoint == AppBreakpoint.compact;
  bool get isMedium => breakpoint == AppBreakpoint.medium;
  bool get isExpanded => breakpoint == AppBreakpoint.expanded;
}
