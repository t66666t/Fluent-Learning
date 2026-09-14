/// Shared visual governance tokens (Phase 9 / beautify U1).
///
/// Single maintenance point for colors, corner radii, motion, and breakpoints.
/// Prefer these over ad-hoc literals in UI code.
library;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Dark-theme layered palette — keep the existing charcoal aesthetic.
abstract final class AppColors {
  // Layered surfaces (darkest → elevated)
  static const Color scaffold = Color(0xFF121212);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceContainer = Color(0xFF1A1A1A);
  static const Color elevated = Color(0xFF1E1E1E);

  /// Soft blue accent (matches prior bootstrap primary).
  static const Color primary = Color(0xFF6EA8FF);
  static const Color onPrimary = Color(0xFF0A1628);

  static const Color onSurface = Color(0xFFE8E8E8);
  static const Color onSurfaceVariant = Color(0xFFB0B0B0);
  static const Color outline = Color(0x3DFFFFFF); // ~white24
  static const Color outlineVariant = Color(0x1FFFFFFF); // ~white12

  /// Muted semantic tones suited to dark backgrounds (not neon).
  static const Color success = Color(0xFF6BBF8A);
  static const Color warning = Color(0xFFD4A574);
  static const Color error = Color(0xFFCF8A8A);
  static const Color onSuccess = Color(0xFF0C1A10);
  static const Color onWarning = Color(0xFF1A1208);
  static const Color onError = Color(0xFF1A0C0C);
}

/// Corner radii — keep within 8–12 for interactive surfaces.
abstract final class AppRadii {
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;

  static BorderRadius get borderSm => BorderRadius.circular(sm);
  static BorderRadius get borderMd => BorderRadius.circular(md);
  static BorderRadius get borderLg => BorderRadius.circular(lg);
}

/// Centralized short motion durations + curves (snappy UI band).
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration emphasized = Duration(milliseconds: 280);

  /// Inline feedback auto-clear window (not a floating toast).
  static const Duration feedbackHold = Duration(milliseconds: 2800);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubic;
  static const Curve decelerate = Curves.easeOut;
  static const Curve accelerate = Curves.easeIn;
}

/// Layout width breakpoints (logical pixels).
abstract final class AppBreakpoints {
  /// Compact (phone): width < [medium].
  static const double compact = 600;

  /// Medium (tablet / narrow desktop): [compact] <= width < [expanded].
  static const double medium = 1024;

  /// Expanded (desktop): width >= [medium] threshold named [expanded] for clarity.
  static const double expanded = 1024;
}
