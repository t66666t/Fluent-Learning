import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fluent_learning/system/model_center/model_center.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('getActive/setActive persists across ModelCenter instances', () async {
    final first = ModelCenter();
    await first.initialize();

    expect(first.getActive(ModelKind.transcription), ModelCenter.bcutAsrId);
    expect(first.getActive(ModelKind.translation), ModelCenter.googleTranslateId);
    expect(first.resolve(ModelKind.qa), isNull);

    await first.setActive(ModelKind.translation, ModelCenter.bingTranslateId);
    expect(first.getActive(ModelKind.translation), ModelCenter.bingTranslateId);
    expect(
      first.resolve(ModelKind.translation)?.id,
      ModelCenter.bingTranslateId,
    );
    expect(first.resolveTranslationProviderName(), 'bing');

    final second = ModelCenter();
    await second.initialize();
    expect(second.getActive(ModelKind.translation), ModelCenter.bingTranslateId);
    expect(
      second.resolve(ModelKind.translation)?.displayName,
      '微软翻译 (Bing)',
    );
  });

  test('remote config fields persist without executing', () async {
    final center = ModelCenter();
    await center.initialize();

    await center.setRemoteConfig(
      ModelKind.qa,
      const ModelKindRemoteConfig(
        localModelPath: '/models/qa.bin',
        apiBaseUrl: 'https://api.example.com',
        apiKey: 'secret-key',
      ),
    );

    expect(center.getRemoteConfig(ModelKind.qa).localModelPath, '/models/qa.bin');
    expect(center.getRemoteConfig(ModelKind.qa).apiBaseUrl, 'https://api.example.com');
    expect(center.getRemoteConfig(ModelKind.qa).apiKey, 'secret-key');

    final again = ModelCenter();
    await again.initialize();
    final cfg = again.getRemoteConfig(ModelKind.qa);
    expect(cfg.localModelPath, '/models/qa.bin');
    expect(cfg.apiBaseUrl, 'https://api.example.com');
    expect(cfg.apiKey, 'secret-key');
    expect(cfg.hasAny, isTrue);
  });

  test('unavailable local whisper cannot become active', () async {
    final center = ModelCenter();
    await center.initialize();
    expect(
      () => center.setActive(ModelKind.transcription, ModelCenter.localWhisperId),
      throwsA(isA<StateError>()),
    );
    expect(center.getActive(ModelKind.transcription), ModelCenter.bcutAsrId);
  });
}
