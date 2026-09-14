import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fluent_learning/app/main_shell.dart';
import 'package:fluent_learning/features/library/library_selection_active.dart';
import 'package:fluent_learning/services/bilibili/bilibili_download_service.dart';
import 'package:fluent_learning/system/download_center/download_center.dart';
import 'package:fluent_learning/system/processing_center/processing_job.dart';
import 'package:fluent_learning/system/processing_center/processing_job_type.dart';
import 'package:fluent_learning/widgets/media_library_empty_state.dart';

/// Mirrors [MainShell] Phase 8/16 bottom-bar hide contract without mounting
/// the full IndexedStack (which needs app-wide Providers).
class _ShellBottomBarProbe extends StatelessWidget {
  const _ShellBottomBarProbe({required this.libraryTabSelected});

  final bool libraryTabSelected;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: librarySelectionActive,
      builder: (context, selectionActive, _) {
        final hide =
            libraryTabSelected && selectionActive;
        if (hide) return const SizedBox.shrink(key: Key('shell-nav-hidden'));
        return NavigationBar(
          key: Key('shell-nav-visible'),
          destinations: [
            NavigationDestination(icon: Icon(Icons.home), label: '首页'),
            NavigationDestination(icon: Icon(Icons.video_library), label: '库'),
          ],
          selectedIndex: 1,
          onDestinationSelected: _noop,
        );
      },
    );
  }

  static void _noop(int _) {}
}

void main() {
  tearDown(() {
    librarySelectionActive.value = false;
  });

  test('MediaLibraryEmptyCopy unifies library/picker search wording', () {
    expect(MediaLibraryEmptyCopy.libraryEmptyTitle, '还没有内容');
    expect(MediaLibraryEmptyCopy.collectionEmptyTitle, '合集是空的');
    expect(MediaLibraryEmptyCopy.searchNoResultsTitle, '没有找到匹配项目');
    expect(MediaLibraryEmptyCopy.pickerEmptyTitle, '暂无媒体');
    expect(MediaLibraryEmptyCopy.pickerFolderEmptyTitle, '此文件夹为空');
  });

  testWidgets('MediaLibraryEmptyState.searchNoResults renders shared copy',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MediaLibraryEmptyState.searchNoResults()),
      ),
    );
    expect(find.text('没有找到匹配项目'), findsOneWidget);
    expect(find.text('试试其他关键词'), findsOneWidget);
    expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
  });

  testWidgets('MediaLibraryEmptyState.pickerEmpty uses compact shared style',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MediaLibraryEmptyState.pickerEmpty()),
      ),
    );
    expect(find.text('暂无媒体'), findsOneWidget);
    expect(find.text('请先导入视频或音频'), findsOneWidget);
  });

  testWidgets(
      'Library multi-select hides shell bottom bar (MainShell contract)',
      (tester) async {
    librarySelectionActive.value = false;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: _ShellBottomBarProbe(libraryTabSelected: true)),
      ),
    );
    expect(find.byKey(const Key('shell-nav-visible')), findsOneWidget);

    librarySelectionActive.value = true;
    await tester.pump();
    expect(find.byKey(const Key('shell-nav-hidden')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    // Other tabs keep the shell bar even if selection notifier is true.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: _ShellBottomBarProbe(libraryTabSelected: false)),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('shell-nav-visible')), findsOneWidget);

    // Tab index constant remains stable for Library.
    expect(MainShellTab.library, 1);
  });

  test('ProcessingJobView carries result fields for success navigation', () {
    const job = ProcessingJobView(
      id: 'pc_1',
      type: ProcessingJobType.transcription,
      phase: ProcessingJobPhase.success,
      title: 'Demo',
      createdAt: 1,
      mediaKey: 'id:v1',
      videoPath: '/tmp/a.mp4',
      videoId: 'v1',
      isExternal: false,
    );
    expect(job.videoId, 'v1');
    expect(job.videoPath, '/tmp/a.mp4');
    expect(job.phase, ProcessingJobPhase.success);
  });

  test('DownloadCenterQueueSummary counts empty bilibili queue as zero', () {
    final service = BilibiliDownloadService();
    expect(DownloadCenterQueueSummary.countBilibiliInProgress(service), 0);
  });
}
