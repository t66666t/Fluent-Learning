/// System Download Center — thin route / entry constants.
///
/// UI lives under `features/centers/download_center_page.dart`.
/// Download engines stay in existing bilibili / youtube_download modules.
library;

/// Named routes used by Download Center and deep-links.
abstract final class DownloadCenterRoutes {
  static const String hall = '/download_center';
  static const String bilibili = '/bilibili_download';
  static const String ytDlp = '/yt_dlp_download';
}
