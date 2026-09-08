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
  final int minValidSizeBytes;
  final String description;
  final int minRamMb;

  const WhisperModelVariant({
    required this.id,
    required this.displayName,
    required this.fileName,
    required this.downloadUrl,
    required this.approximateSizeMb,
    required this.minValidSizeBytes,
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
      minValidSizeBytes: 70 * 1024 * 1024, // ~74 MB exact
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
      minValidSizeBytes: 140 * 1024 * 1024, // ~141 MB exact
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
      minValidSizeBytes: 450 * 1024 * 1024, // ~465 MB exact
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

      // Clean up any stale partial downloads (.part files)
      try {
        final dirEntities = await modelDir.list().toList();
        for (final entity in dirEntities) {
          if (entity is File && entity.path.endsWith('.part')) {
            await entity.delete().catchError((_) => entity);
          }
        }
      } catch (_) {}

      for (final variant in availableModels) {
        final file = File('${modelDir.path}/${variant.fileName}');
        if (await file.exists()) {
          final fileSize = await file.length();
          if (fileSize >= variant.minValidSizeBytes) {
            // Fully intact valid model file
            _updateStatus(ModelInfo(
              name: variant.displayName,
              fileName: variant.fileName,
              sizeMb: (fileSize / (1024 * 1024)).round(),
              path: file.path,
              status: ModelStatus.installed,
            ));
            return true;
          } else {
            // Corrupt or truncated partial file from an earlier interrupted download!
            // Automatically clean it up so it doesn't cause crashes or false 'installed' status.
            if (kDebugMode) {
              print('[OfflineModelManager] Found truncated ${variant.fileName} ($fileSize bytes < ${variant.minValidSizeBytes} bytes). Deleting corrupt file.');
            }
            try {
              await file.delete();
            } catch (_) {}
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
    final modelDir = await _modelDirectory();
    final targetPath = '${modelDir.path}/${model.fileName}';
    final partPath = '$targetPath.part';
    final partFile = File(partPath);

    HttpClient? client;
    IOSink? sink;

    try {
      _updateStatus(ModelInfo(
        name: model.displayName,
        fileName: model.fileName,
        status: ModelStatus.downloading,
        downloadProgress: 0.0,
      ));

      // Remove stale .part file if present
      if (await partFile.exists()) {
        await partFile.delete();
      }

      // Download using HTTP with redirect support and progress throttling
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);
      client.idleTimeout = const Duration(seconds: 60);

      final request = await client.getUrl(model.downloadUrl);
      request.followRedirects = true;
      request.maxRedirects = 5;

      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Download failed with HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength;
      int receivedBytes = 0;

      sink = partFile.openWrite();

      DateTime lastProgressTime = DateTime.now();
      double lastReportedProgress = 0.0;

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        final progress = totalBytes > 0
            ? (receivedBytes / totalBytes).clamp(0.0, 1.0)
            : 0.0;

        // Throttle UI updates to at most once per 150ms or 2% delta
        // to avoid flooding the Flutter UI thread and causing frame drops
        final now = DateTime.now();
        if (now.difference(lastProgressTime).inMilliseconds >= 150 ||
            (progress - lastReportedProgress).abs() >= 0.02 ||
            receivedBytes == totalBytes) {
          lastProgressTime = now;
          lastReportedProgress = progress;
          progressController.add(progress);
          _updateStatus(_currentModel.copyWith(downloadProgress: progress));
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;
      client.close();
      client = null;

      // Verify downloaded file size integrity
      final downloadedBytes = await partFile.length();
      if (downloadedBytes < model.minValidSizeBytes) {
        await partFile.delete();
        throw Exception(
          'Downloaded model file was incomplete (${(downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB of ~${model.approximateSizeMb} MB). Please try downloading again.',
        );
      }

      // Atomically install the model file
      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await partFile.rename(targetPath);

      _updateStatus(ModelInfo(
        name: model.displayName,
        fileName: model.fileName,
        sizeMb: (downloadedBytes / (1024 * 1024)).round(),
        path: targetPath,
        status: ModelStatus.installed,
        downloadProgress: 1.0,
      ));

      progressController.add(1.0);
      await progressController.close();

      if (kDebugMode) {
        print(
          '[OfflineModelManager] Model successfully verified and installed: ${model.displayName} (${(downloadedBytes / (1024 * 1024)).round()} MB)',
        );
      }
    } catch (e) {
      // Clean up sink and client safely
      try {
        await sink?.close();
      } catch (_) {}
      try {
        client?.close();
      } catch (_) {}

      // Clean up temporary .part file on error
      try {
        if (await partFile.exists()) {
          await partFile.delete();
        }
      } catch (_) {}

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

    // Verify model is installed on disk
    final installed = await isModelInstalled();
    if (!installed || _currentModel.path.isEmpty) {
      if (kDebugMode) {
        print('[OfflineModelManager] loadModel failed: Model is not installed on disk.');
      }
      return null;
    }

    final file = File(_currentModel.path);
    if (!await file.exists()) {
      _updateStatus(const ModelInfo(
        name: 'Not Installed',
        fileName: '',
        status: ModelStatus.notInstalled,
      ));
      return null;
    }

    try {
      _updateStatus(_currentModel.copyWith(status: ModelStatus.loading));

      if (kDebugMode) {
        print('[OfflineModelManager] Loading Whisper engine from: ${_currentModel.path} (${_currentModel.name})');
      }

      _engine = await WhisperEngine.load(_currentModel.path);

      _updateStatus(_currentModel.copyWith(status: ModelStatus.ready));

      if (kDebugMode) {
        print('[OfflineModelManager] Whisper engine loaded and ready: ${_currentModel.name}');
      }

      return _engine;
    } catch (e) {
      _updateStatus(_currentModel.copyWith(
        status: ModelStatus.error,
        errorMessage: 'Failed to initialize ${_currentModel.name} model ($e). Try the Tiny (75 MB) or Base (142 MB) model if device RAM is limited.',
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
