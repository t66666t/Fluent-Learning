import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_learning/features/learning_unit/data/learning_unit_repository.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit.dart';

void main() {
  late LearningUnitRepository repo;

  setUp(() {
    repo = LearningUnitRepository();
    repo.persistToDisk = false;
  });

  test('playback progress aggregates percent and auto-completes at 90%', () async {
    final unit = await repo.create(
      title: 'Unit',
      itemRefs: const [
        LearningUnitItemRef.media('m1'),
        LearningUnitItemRef.media('m2'),
      ],
    );

    await repo.syncMediaProgress(
      mediaId: 'm1',
      watchedMs: 500,
      durationMs: 1000,
    );
    var updated = repo.getById(unit.id)!;
    expect(updated.progress.watchedMsByMedia['m1'], 500);
    expect(updated.progress.percent, closeTo(0.25, 0.001));
    expect(updated.status, LearningUnitStatus.active);
    expect(repo.isLeafComplete(updated, 'm1'), isFalse);

    await repo.syncMediaProgress(
      mediaId: 'm1',
      watchedMs: 900,
      durationMs: 1000,
    );
    updated = repo.getById(unit.id)!;
    expect(repo.isLeafComplete(updated, 'm1'), isTrue);
    expect(updated.progress.percent, closeTo(0.5, 0.001));
    expect(updated.status, isNot(LearningUnitStatus.completed));

    await repo.syncMediaProgress(
      mediaId: 'm2',
      watchedMs: 950,
      durationMs: 1000,
    );
    updated = repo.getById(unit.id)!;
    expect(repo.isLeafComplete(updated, 'm2'), isTrue);
    expect(updated.progress.percent, closeTo(1.0, 0.001));
    expect(updated.status, LearningUnitStatus.completed);
    expect(updated.completedAt, isNotNull);
  });

  test('manual complete of all leaves marks the unit completed', () async {
    final unit = await repo.create(
      title: 'Manual',
      itemRefs: const [LearningUnitItemRef.media('only')],
    );
    await repo.markMediaComplete(unit.id, 'only', completed: true);
    final updated = repo.getById(unit.id)!;
    expect(updated.status, LearningUnitStatus.completed);
    expect(updated.progress.percent, 1.0);
    expect(repo.nextIncompleteMediaId(updated), isNull);
  });

  test('progress does not go backwards', () async {
    final unit = await repo.create(
      title: 'Fwd',
      itemRefs: const [LearningUnitItemRef.media('m')],
    );
    await repo.syncMediaProgress(mediaId: 'm', watchedMs: 400, durationMs: 1000);
    await repo.syncMediaProgress(mediaId: 'm', watchedMs: 100, durationMs: 1000);
    expect(repo.getById(unit.id)!.progress.watchedMsByMedia['m'], 400);
  });
}
