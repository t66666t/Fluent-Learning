import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_learning/domain/sync/sync.dart';
import 'package:fluent_learning/features/learning_unit/data/learning_unit_repository.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit.dart';
import 'package:fluent_learning/models/video_item.dart';

void main() {
  test('export then import LearningUnits retains key fields', () async {
    final createdAt = DateTime.utc(2026, 9, 10, 8);
    final updatedAt = DateTime.utc(2026, 9, 14, 6);
    final original = LearningUnit(
      id: 'unit-roundtrip-1',
      title: 'Phase12 RoundTrip',
      notes: 'keep me',
      status: LearningUnitStatus.active,
      itemRefs: const [
        LearningUnitItemRef.media('media-a'),
        LearningUnitItemRef.folder('folder-b', includeNested: false),
      ],
      schedule: LearningUnitSchedule(
        dueDate: DateTime.utc(2026, 9, 20),
        targetMinutesPerDay: 25,
        weekdayMask: 0x1F,
      ),
      progress: const LearningUnitProgress(
        completedMediaIds: <String>['media-a'],
        watchedMsByMedia: <String, int>{'media-a': 900},
        percent: 0.5,
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
      revision: 3,
    );

    final source = LearningUnitRepository()..persistToDisk = false;
    await source.importMetadataBundle(
      MetadataSyncBundle.export(learningUnits: [original]),
    );

    final media = VideoItem(
      id: 'media-a',
      path: '/tmp/demo.mp4',
      title: 'Demo',
      durationMs: 120000,
      lastUpdated: DateTime.utc(2026, 9, 14).millisecondsSinceEpoch,
      syncRevision: 1,
    );

    final bundle = MetadataSyncBundle.export(
      learningUnits: source.allUnitsForSync,
      mediaMetadata: [MediaSyncMetadata.fromVideoItem(media)],
      exportedAt: DateTime.utc(2026, 9, 14, 7),
    );
    final encoded = bundle.encodePretty();
    final decoded = MetadataSyncBundle.decode(encoded);

    expect(decoded.format, MetadataSyncBundle.formatId);
    expect(decoded.learningUnits, hasLength(1));
    expect(decoded.mediaMetadata, hasLength(1));
    expect(decoded.mediaMetadata.single.pathHint, '/tmp/demo.mp4');
    expect(decoded.mediaMetadata.single.revision, 1);
    expect(decoded.mediaMetadata.single, isA<SyncEntity>());

    final target = LearningUnitRepository()..persistToDisk = false;
    final result = await target.importMetadataBundle(decoded);
    expect(result.upserted, 1);
    expect(result.mediaRows, 1);

    final imported = target.getById(original.id)!;
    expect(imported, isA<SyncEntity>());
    expect(imported.id, original.id);
    expect(imported.title, 'Phase12 RoundTrip');
    expect(imported.notes, 'keep me');
    expect(imported.status, LearningUnitStatus.active);
    expect(imported.revision, 3);
    expect(imported.itemRefs.map((e) => e.mediaId).toList(), ['media-a', null]);
    expect(
      imported.itemRefs.map((e) => e.folderId).toList(),
      [null, 'folder-b'],
    );
    expect(imported.itemRefs[1].includeNested, isFalse);
    expect(imported.schedule.dueDate, DateTime.utc(2026, 9, 20));
    expect(imported.schedule.targetMinutesPerDay, 25);
    expect(imported.schedule.weekdayMask, 0x1F);
    expect(imported.progress.completedMediaIds, contains('media-a'));
    expect(imported.progress.watchedMsByMedia['media-a'], 900);
    expect(imported.progress.percent, 0.5);
    expect(imported.updatedAt.toUtc(), updatedAt);
    expect(imported.createdAt.toUtc(), createdAt);
  });

  test('import prefers newer updatedAt over older revision', () async {
    final repo = LearningUnitRepository()..persistToDisk = false;
    const id = 'conflict-1';
    final base = LearningUnit(
      id: id,
      title: 'Base',
      itemRefs: const [LearningUnitItemRef.media('m')],
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    await repo.importMetadataBundle(
      MetadataSyncBundle.export(learningUnits: [base]),
    );

    final olderNewerRevision = base.copyWith(
      title: 'Older but rev 9',
      revision: 9,
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    final newerLowerRevision = base.copyWith(
      title: 'Newer rev 1',
      revision: 1,
      updatedAt: DateTime.utc(2026, 6, 1),
    );
    await repo.importMetadataBundle(
      MetadataSyncBundle.export(learningUnits: [olderNewerRevision]),
    );
    await repo.importMetadataBundle(
      MetadataSyncBundle.export(learningUnits: [newerLowerRevision]),
    );
    expect(repo.getById(id)!.title, 'Newer rev 1');
    expect(repo.getById(id)!.revision, 1);
  });
}
