/// System Download Center — thin route / entry constants + queue summaries.
///
/// UI lives under `features/centers/download_center_page.dart`.
/// Download engines stay in existing bilibili / youtube_download modules.
library;

import 'package:fluent_learning/features/youtube_download/services/yt_dlp_download_service.dart';
import 'package:fluent_learning/models/bilibili_download_task.dart';
import 'package:fluent_learning/services/bilibili/bilibili_download_service.dart';

/// Named routes used by Download Center and deep-links.
abstract final class DownloadCenterRoutes {
  static const String hall = '/download_center';
  static const String bilibili = '/bilibili_download';
  static const String ytDlp = '/yt_dlp_download';
}

/// Lightweight in-progress counters for Centers hall badges (Phase 16).
abstract final class DownloadCenterQueueSummary {
  static int countBilibiliInProgress(BilibiliDownloadService service) {
    var count = 0;
    for (final task in service.tasks) {
      for (final video in task.videos) {
        for (final ep in video.episodes) {
          switch (ep.status) {
            case DownloadStatus.queued:
            case DownloadStatus.fetchingInfo:
            case DownloadStatus.downloading:
            case DownloadStatus.merging:
            case DownloadStatus.checking:
            case DownloadStatus.repairing:
              count++;
              break;
            case DownloadStatus.pending:
            case DownloadStatus.completed:
            case DownloadStatus.failed:
              break;
          }
        }
      }
    }
    return count;
  }

  static int countYtDlpInProgress(YtDlpDownloadService service) =>
      service.activeCount + service.queuedCount;

  static int totalInProgress(
    BilibiliDownloadService bilibili,
    YtDlpDownloadService ytDlp,
  ) {
    return countBilibiliInProgress(bilibili) + countYtDlpInProgress(ytDlp);
  }
}
