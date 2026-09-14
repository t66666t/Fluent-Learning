import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_learning/app/theme.dart';
import 'package:fluent_learning/system/feedback/feedback.dart';

void main() {
  test('theme tokens stay in governance band', () {
    expect(AppRadii.sm, inInclusiveRange(8, 12));
    expect(AppRadii.md, inInclusiveRange(8, 12));
    expect(AppRadii.lg, inInclusiveRange(8, 12));
    expect(AppMotion.fast.inMilliseconds, inInclusiveRange(200, 280));
    expect(AppMotion.normal.inMilliseconds, inInclusiveRange(200, 280));
    expect(AppMotion.emphasized.inMilliseconds, inInclusiveRange(200, 280));
  });

  test('buildAppDarkTheme wires radii into button shapes', () {
    final theme = buildAppDarkTheme(
      baseTextTheme: ThemeData.dark(useMaterial3: true).textTheme,
    );
    final shape = theme.filledButtonTheme.style?.shape?.resolve({});
    expect(shape, isA<RoundedRectangleBorder>());
    final border = shape as RoundedRectangleBorder;
    expect(border.borderRadius, AppRadii.borderMd);
  });

  testWidgets('AppInlineBanner renders success message without overlay',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppInlineBanner(
            message: AppFeedbackMessage(
              text: '已加入处理队列',
              tone: AppFeedbackTone.success,
              title: '入队成功',
            ),
          ),
        ),
      ),
    );
    expect(find.text('入队成功'), findsOneWidget);
    expect(find.text('已加入处理队列'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  test('AppFeedback helpers', () {
    final enqueue = AppFeedback.enqueueSuccess(jobId: 'pc_1', queuePosition: 2);
    expect(enqueue.tone, AppFeedbackTone.success);
    expect(enqueue.text, contains('顺位：2'));
    expect(enqueue.text, contains('pc_1'));

    final save = AppFeedback.saveSuccess();
    expect(save.tone, AppFeedbackTone.success);

    final download = AppFeedback.downloadStarted('已创建 3 个下载任务');
    expect(download.text, '已创建 3 个下载任务');
  });
}
