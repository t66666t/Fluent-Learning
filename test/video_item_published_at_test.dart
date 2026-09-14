import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_learning/models/video_item.dart';

void main() {
  test('publishedAt roundtrips and is nullable for legacy JSON', () {
    final item = VideoItem(
      id: 't1',
      path: '/tmp/a.mp4',
      title: 'Demo',
      durationMs: 1000,
      lastUpdated: 1,
      publishedAt: 1700000000000,
    );
    final restored = VideoItem.fromJson(item.toJson());
    expect(restored.publishedAt, 1700000000000);

    final legacy = VideoItem.fromJson({
      'id': 't2',
      'path': '/tmp/b.mp4',
      'title': 'Legacy',
      'durationMs': 0,
      'lastUpdated': 1,
    });
    expect(legacy.publishedAt, isNull);
  });
}
