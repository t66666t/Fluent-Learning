/// Page-local / inline feedback (Phase 9).
///
/// Prefer [AppInlineBanner] and button loading states over floating toasts
/// for critical paths (enqueue, save unit, download start).
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:fluent_learning/core/theme_tokens.dart';

enum AppFeedbackTone { info, success, error, loading }

/// Immutable snapshot for page-owned inline feedback.
@immutable
class AppFeedbackMessage {
  const AppFeedbackMessage({
    required this.text,
    this.tone = AppFeedbackTone.info,
    this.title,
  });

  final String text;
  final AppFeedbackTone tone;
  final String? title;

  factory AppFeedbackMessage.info(String text, {String? title}) =>
      AppFeedbackMessage(text: text, tone: AppFeedbackTone.info, title: title);

  factory AppFeedbackMessage.success(String text, {String? title}) =>
      AppFeedbackMessage(
        text: text,
        tone: AppFeedbackTone.success,
        title: title,
      );

  factory AppFeedbackMessage.error(String text, {String? title}) =>
      AppFeedbackMessage(text: text, tone: AppFeedbackTone.error, title: title);

  factory AppFeedbackMessage.loading(String text, {String? title}) =>
      AppFeedbackMessage(
        text: text,
        tone: AppFeedbackTone.loading,
        title: title,
      );
}

/// Helpers for building / clearing page-local feedback (no overlay / toast).
abstract final class AppFeedback {
  /// Convenience: build a success message for enqueue paths.
  static AppFeedbackMessage enqueueSuccess({
    String? jobId,
    int? queuePosition,
  }) {
    final buffer = StringBuffer('已加入处理队列');
    if (queuePosition != null && queuePosition > 0) {
      buffer.write('，当前顺位：$queuePosition');
    }
    if (jobId != null && jobId.isNotEmpty) {
      buffer.write('\n任务 ID：$jobId');
    }
    return AppFeedbackMessage.success(
      buffer.toString(),
      title: '入队成功',
    );
  }

  static AppFeedbackMessage saveSuccess([String text = '已保存']) =>
      AppFeedbackMessage.success(text, title: '保存成功');

  static AppFeedbackMessage downloadStarted([String text = '下载已开始']) =>
      AppFeedbackMessage.success(text, title: '下载');
}

/// Compact inline banner — use inside page/panel layouts, not as an overlay.
class AppInlineBanner extends StatelessWidget {
  const AppInlineBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.dense = false,
  });

  final AppFeedbackMessage message;
  final VoidCallback? onDismiss;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (Color accent, IconData icon) = switch (message.tone) {
      AppFeedbackTone.success => (Colors.tealAccent, Icons.check_circle_outline),
      AppFeedbackTone.error => (Colors.redAccent, Icons.error_outline),
      AppFeedbackTone.loading => (Colors.lightBlueAccent, Icons.hourglass_top),
      AppFeedbackTone.info => (Colors.blueGrey, Icons.info_outline),
    };

    final padding = dense
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        : const EdgeInsets.all(12);

    return AnimatedSize(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: Material(
        color: accent.withValues(alpha: 0.12),
        borderRadius: AppRadii.borderMd,
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: AppRadii.borderMd,
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.tone == AppFeedbackTone.loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accent,
                  ),
                )
              else
                Icon(icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.title != null) ...[
                      Text(
                        message.title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.close, size: 16, color: Colors.white38),
                  onPressed: onDismiss,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mixin for StatefulWidget pages that own a brief inline feedback banner.
///
/// Does **not** create floating toasts — only local state for [AppInlineBanner].
mixin AppInlineFeedbackMixin<T extends StatefulWidget> on State<T> {
  AppFeedbackMessage? inlineFeedback;
  Timer? _inlineFeedbackTimer;

  void showInlineFeedback(
    AppFeedbackMessage message, {
    Duration? hold,
    bool autoClear = true,
  }) {
    _inlineFeedbackTimer?.cancel();
    setState(() => inlineFeedback = message);
    if (!autoClear || message.tone == AppFeedbackTone.loading) return;
    _inlineFeedbackTimer = Timer(hold ?? AppMotion.feedbackHold, () {
      if (!mounted) return;
      setState(() => inlineFeedback = null);
    });
  }

  void clearInlineFeedback() {
    _inlineFeedbackTimer?.cancel();
    if (inlineFeedback == null) return;
    setState(() => inlineFeedback = null);
  }

  @override
  void dispose() {
    _inlineFeedbackTimer?.cancel();
    super.dispose();
  }

  Widget? buildInlineFeedbackBanner({bool dense = false}) {
    final msg = inlineFeedback;
    if (msg == null) return null;
    return AppInlineBanner(
      message: msg,
      dense: dense,
      onDismiss: clearInlineFeedback,
    );
  }
}
