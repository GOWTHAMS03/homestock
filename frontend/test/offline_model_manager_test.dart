import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/features/voice/data/speech/offline_model_manager.dart';

void main() {
  group('OfflineModelManager Tests', () {
    test('availableModels has all required multilingual variants', () {
      final models = OfflineModelManager.availableModels;
      expect(models.length, equals(3));

      final tiny = models.firstWhere((m) => m.id == 'tiny');
      expect(tiny.displayName, equals('Tiny'));
      expect(tiny.fileName, equals('ggml-tiny.bin'));
      expect(tiny.approximateSizeMb, equals(75));
      expect(tiny.downloadUrl.toString(), contains('ggml-tiny.bin'));

      final base = models.firstWhere((m) => m.id == 'base');
      expect(base.displayName, equals('Base'));
      expect(base.fileName, equals('ggml-base.bin'));
      expect(base.approximateSizeMb, equals(142));
      expect(base.downloadUrl.toString(), contains('ggml-base.bin'));

      final small = models.firstWhere((m) => m.id == 'small');
      expect(small.displayName, equals('Small'));
      expect(small.fileName, equals('ggml-small.bin'));
      expect(small.approximateSizeMb, equals(466));
      expect(small.downloadUrl.toString(), contains('ggml-small.bin'));
    });

    test('recommendedModel returns base model for balanced performance', () {
      final recommended = OfflineModelManager.recommendedModel();
      expect(recommended.id, equals('base'));
      expect(recommended.approximateSizeMb, equals(142));
    });

    test('ModelInfo copyWith works properly', () {
      const initial = ModelInfo(
        name: 'Not Installed',
        fileName: '',
        status: ModelStatus.notInstalled,
      );
      expect(initial.status, equals(ModelStatus.notInstalled));
      expect(initial.downloadProgress, equals(0.0));

      final downloading = initial.copyWith(
        name: 'Base',
        fileName: 'ggml-base.bin',
        status: ModelStatus.downloading,
        downloadProgress: 0.45,
      );
      expect(downloading.name, equals('Base'));
      expect(downloading.status, equals(ModelStatus.downloading));
      expect(downloading.downloadProgress, equals(0.45));

      final installed = downloading.copyWith(
        status: ModelStatus.installed,
        sizeMb: 142,
        path: '/data/user/0/com.homestock/app_flutter/whisper_models/ggml-base.bin',
        downloadProgress: 1.0,
      );
      expect(installed.status, equals(ModelStatus.installed));
      expect(installed.sizeMb, equals(142));
      expect(installed.path, contains('ggml-base.bin'));
    });

    test('OfflineModelManager initial state', () {
      final manager = OfflineModelManager();
      expect(manager.currentModel.status, equals(ModelStatus.notInstalled));
      expect(manager.isModelReady, isFalse);
      expect(manager.isEngineLoaded, isFalse);
      expect(manager.engine, isNull);
      manager.dispose();
    });
  });
}
