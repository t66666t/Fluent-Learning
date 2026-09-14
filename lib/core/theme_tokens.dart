/// Shared visual governance tokens (Phase 9).
///
/// Single maintenance point for corner radii and motion durations.
/// Prefer these over ad-hoc `BorderRadius.circular(...)` / `Duration(...)`.
library;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Corner radii — keep within 8–12 for interactive surfaces.
abstract final class AppRadii {
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;

  static BorderRadius get borderSm => BorderRadius.circular(sm);
  static BorderRadius get borderMd => BorderRadius.circular(md);
  static BorderRadius get borderLg => BorderRadius.circular(lg);
}

/// Centralized short motion durations (200–280ms band).
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration emphasized = Duration(milliseconds: 280);

  /// Inline feedback auto-clear window (not a floating toast).
  static const Duration feedbackHold = Duration(milliseconds: 2800);

  static const Curve standard = Curves.easeOutCubic;
}
