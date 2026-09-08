import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_cpp_flutter_plus/whisper_cpp_flutter_plus.dart';

/// Describes a downloadable Whisper model variant
class WhisperModelVariant {
  final String id;
  final String displayName;
  final String fileName;
  final Uri downloadUrl;
  final int approximateSizeMb;
  final String description;
  final int minRamMb;

  const WhisperModelVariant({
    required this.id,
    required this.displayName,
    required this.fileName,
    required this.downloadUrl,
    required this.approximateSizeMb,
    required this.description,
    this.minRamMb = 0,
  });
}

/// Status of the offline whisper model
enum ModelStatus {
  notInstalled,
  downloading,
  installed,
  loading,
  ready,
  error,
}

/// Information about the currently installed model
class ModelInfo {
  final String name;
  final String fileName;
  final int sizeMb;
  final String path;
  final ModelStatus status;
  final double downloadProgress;
  final String? errorMessage;

  const ModelInfo({
    required this.name,
    required this.fileName,
    this.sizeMb = 0,
    this.path = '',
    this.status = ModelStatus.notInstalled,
    this.downloadProgress = 0.0,
    this.errorMessage,
  });

  ModelInfo copyWith({
    String? name,
    String? fileName,
    int? sizeMb,
    String? path,
    ModelStatus? status,
    double? downloadProgress,
    String? errorMessage,
  }) {
    return ModelInfo(
      name: name ?? this.name,
      fileName: fileName ?? this.fileName,
      sizeMb: sizeMb ?? this.sizeMb,
      path: path ?? this.path,
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Manages the lifecycle of offline Whisper models:
/// download, verify, load, unload, delete, update.
///
/// Uses `whisper_cpp_flutter_plus` WhisperModelManager internally.
class OfflineModelManager {
  WhisperEngine? _engine;
  ModelInfo _currentModel = const ModelInfo(
    name: 'Not Installed',
    fileName: '',
    status: ModelStatus.notInstalled,
  );

  final _statusController = StreamController<ModelInfo>.broadcast();

  /// Stream of model status changes
  Stream<ModelInfo> get statusStream => _statusController.stream;

  /// Current model info (synchronous)
  ModelInfo get currentModel => _currentModel;

  /// Currently loaded WhisperEngine (null if not loaded)
  WhisperEngine? get engine => _engine;

  /// Whether a model is installed and ready for transcription
  bool get isModelReady =>
      _currentModel.status == ModelStatus.ready ||
      _currentModel.status == ModelStatus.installed;

  /// Whether the engine is loaded in memory
  bool get isEngineLoaded => _engine != null;

  // ─── Available Model Variants ──────────────────────────────────────

  /// All multilingual models (NOT .en variants — required for Tamil + English)
  static final List<WhisperModelVariant> availableModels = [
    WhisperModelVariant(
      id: 'tiny',
      displayName: 'Tiny',
      fileName: 'ggml-tiny.bin',
      downloadUrl: Uri.parse(
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin',
      ),
      approximateSizeMb: 75,
      description: 'Fast, lower accuracy. Best for low-end devices.',
      minRamMb: 1024,
    ),
    WhisperModelVariant(
      id: 'base',
      displayName: 'Base',
      fileName: 'ggml-base.bin',
      downloadUrl: Uri.parse(
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin',
      ),
      approximateSizeMb: 142,
      description: 'Balanced speed & accuracy. Recommended for most devices.',
      minRamMb: 2048,
    ),
    WhisperModelVariant(
      id: 'small',
      displayName: 'Small',
      fileName: 'ggml-small.bin',
      downloadUrl: Uri.parse(
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin',
      ),
      approximateSizeMb: 466,
      description: 'Best Tamil & English accuracy. Requires 4+ GB RAM.',
      minRamMb: 4096,
    ),
  ];

  /// Returns the recommended model variant based on available device RAM
  static WhisperModelVariant recommendedModel() {
    // Default to 'base' — good balance for most Android phones
    return availableModels.firstWhere((m) => m.id == 'base');
  }

  // ─── Model Directory ──────────────────────────────────────────────

  Future<Directory> _modelDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    final modelDir = Directory('${appDir.path}/whisper_models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir;
  }

  // ─── Check Installation ───────────────────────────────────────────

  /// Checks if any model is installed and updates status
  Future<bool> isModelInstalled() async {
    try {
      final modelDir = await _modelDirectory();
      for (final variant in availableModels) {
        final file = File('${modelDir.path}/${variant.fileName}');
        if (await file.exists()) {
          final fileSize = await file.length();
          if (fileSize > 1024 * 1024) {
            // At least 1 MB — not a corrupt partial download
            _updateStatus(ModelInfo(
              name: variant.displayName,
              fileName: variant.fileName,
              sizeMb: (fileSize / (1024 * 1024)).round(),
              path: file.path,
              status: ModelStatus.installed,
            ));
            return true;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('[OfflineModelManager] isModelInstalled error: $e');
    }

    _updateStatus(const ModelInfo(
      name: 'Not Installed',
      fileName: '',
      status: ModelStatus.notInstalled,
    ));
    return false;
  }

  // ─── Download ─────────────────────────────────────────────────────

  /// Downloads a Whisper model to device storage.
  /// Returns a stream of download progress (0.0 to 1.0).
  Stream<double> downloadModel([WhisperModelVariant? variant]) {
    final model = variant ?? recommendedModel();
    final controller = StreamController<double>();

    _downloadAsync(model, controller);

    return controller.stream;
  }

  Future<void> _downloadAsync(
    WhisperModelVariant model,
    StreamController<double> progressController,
  ) async {
    try {
      _updateStatus(ModelInfo(
        name: model.displayName,
        fileName: model.fileName,
        status: ModelStatus.downloading,
        downloadProgress: 0.0,
      ));

      final modelDir = await _modelDirectory();
      final targetPath = '${modelDir.path}/${model.fileName}';
      final targetFile = File(targetPath);

      // Delete partial downloads
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      // Download using HTTP with progress tracking
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);

      final request = await client.getUrl(model.downloadUrl);
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Download failed with HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength;
      int receivedBytes = 0;

      final sink = targetFile.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        final progress = totalBytes > 0 ? receivedBytes / totalBytes : 0.0;

        progressController.add(progress);

        _updateStatus(_currentModel.copyWith(
          downloadProgress: progress,
        ));
      }

      await sink.close();
      client.close();

      // Verify download
      final fileSize = await targetFile.length();
      if (fileSize < 1024 * 1024) {
        await targetFile.delete();
        throw Exception('Downloaded file is too small — likely corrupt');
      }

      _updateStatus(ModelInfo(
        name: model.displayName,
        fileName: model.fileName,
        sizeMb: (fileSize / (1024 * 1024)).round(),
        path: targetPath,
        status: ModelStatus.installed,
        downloadProgress: 1.0,
      ));

      progressController.add(1.0);
      await progressController.close();

      if (kDebugMode) {
        print('[OfflineModelManager] Model downloaded: ${model.displayName} (${(fileSize / (1024 * 1024)).round()} MB)');
      }
    } catch (e) {
      _updateStatus(_currentModel.copyWith(
        status: ModelStatus.error,
        errorMessage: 'Download failed: $e',
      ));
      progressController.addError(e);
      await progressController.close();
    }
  }

  // ─── Load Engine ──────────────────────────────────────────────────

  /// Loads the installed Whisper model into memory for transcription.
  /// Must be called before transcription. Reuses existing engine if already loaded.
  Future<WhisperEngine?> loadModel() async {
    if (_engine != null) return _engine;

    if (_currentModel.status == ModelStatus.notInstalled) {
      final installed = await isModelInstalled();
      if (!installed) return null;
    }

    if (_currentModel.path.isEmpty) return null;

    try {
      _updateStatus(_currentModel.copyWith(status: ModelStatus.loading));

      _engine = await WhisperEngine.load(_currentModel.path);

      _updateStatus(_currentModel.copyWith(status: ModelStatus.ready));

      if (kDebugMode) {
        print('[OfflineModelManager] Whisper engine loaded: ${_currentModel.name}');
      }

      return _engine;
    } catch (e) {
      _updateStatus(_currentModel.copyWith(
        status: ModelStatus.error,
        errorMessage: 'Failed to load model: $e',
      ));
      if (kDebugMode) print('[OfflineModelManager] Load error: $e');
      return null;
    }
  }

  // ─── Unload Engine ────────────────────────────────────────────────

  /// Releases the Whisper engine from memory
  void unloadModel() {
    try {
      _engine?.dispose();
    } catch (_) {}
    _engine = null;

    if (_currentModel.status == ModelStatus.ready) {
      _updateStatus(_currentModel.copyWith(status: ModelStatus.installed));
    }

    if (kDebugMode) print('[OfflineModelManager] Engine unloaded');
  }

  // ─── Delete Model ─────────────────────────────────────────────────

  /// Deletes the installed model from device storage
  Future<void> deleteModel() async {
    unloadModel();

    try {
      final modelDir = await _modelDirectory();
      for (final variant in availableModels) {
        final file = File('${modelDir.path}/${variant.fileName}');
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      if (kDebugMode) print('[OfflineModelManager] Delete error: $e');
    }

    _updateStatus(const ModelInfo(
      name: 'Not Installed',
      fileName: '',
      status: ModelStatus.notInstalled,
    ));
  }

  // ─── Model Info ───────────────────────────────────────────────────

  /// Gets the size of the installed model in MB
  Future<int> getModelSizeMb() async {
    if (_currentModel.path.isEmpty) return 0;
    try {
      final file = File(_currentModel.path);
      if (await file.exists()) {
        final bytes = await file.length();
        return (bytes / (1024 * 1024)).round();
      }
    } catch (_) {}
    return 0;
  }

  /// Verify the model file integrity (basic size check)
  Future<bool> verifyModel() async {
    if (_currentModel.path.isEmpty) return false;
    try {
      final file = File(_currentModel.path);
      if (!await file.exists()) return false;
      final size = await file.length();
      return size > 10 * 1024 * 1024; // At least 10 MB
    } catch (_) {
      return false;
    }
  }

  // ─── Internal ─────────────────────────────────────────────────────

  void _updateStatus(ModelInfo info) {
    _currentModel = info;
    _statusController.add(info);
  }

  /// Dispose resources
  void dispose() {
    unloadModel();
    _statusController.close();
  }
}
