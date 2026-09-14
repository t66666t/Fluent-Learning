import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:fluent_learning/domain/sync/media_sync_metadata.dart';
import 'package:fluent_learning/domain/sync/metadata_sync_codec.dart';
import 'package:fluent_learning/features/learning_unit/data/learning_unit_repository.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit.dart';
import 'package:fluent_learning/models/video_item.dart';

/// File I/O helpers for Phase 12 metadata export / import (no video blobs).
abstract final class MetadataSyncIo {
  static Future<File> writeExportFile({
    required Iterable<LearningUnit> learningUnits,
    Iterable<VideoItem> mediaItems = const <VideoItem>[],
    Directory? targetDirectory,
  }) async {
    final media = mediaItems
        .map(MediaSyncMetadata.fromVideoItem)
        .toList(growable: false);
    final bundle = MetadataSyncBundle.export(
      learningUnits: learningUnits,
      mediaMetadata: media,
    );
    final dir = targetDirectory ?? await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(dir.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(
      p.join(exportDir.path, 'fluent_learning_metadata_$stamp.json'),
    );
    await file.writeAsString(bundle.encodePretty(), flush: true);
    return file;
  }

  static Future<ShareResult> shareExportFile(File file) {
    return SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path)],
        subject: 'Fluent Learning metadata export',
        text: 'Metadata only (no video files).',
      ),
    );
  }

  static Future<MetadataSyncBundle?> pickAndDecodeBundle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    String raw;
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      raw = String.fromCharCodes(file.bytes!);
    } else if (file.path != null && file.path!.isNotEmpty) {
      raw = await File(file.path!).readAsString();
    } else {
      throw const FormatException('无法读取所选 JSON 文件');
    }
    return MetadataSyncBundle.decode(raw);
  }

  static Future<MetadataSyncImportResult> importBundleIntoRepository({
    required LearningUnitRepository repository,
    required MetadataSyncBundle bundle,
  }) {
    return repository.importMetadataBundle(bundle);
  }
}
