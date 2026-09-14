import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/sync/sync_providers.dart' show connectivityMonitorProvider;
import '../models/ai_voice_settings.dart';

enum AiVoiceStatus {
  idle,
  loading,
  playing,
  paused,
  error,
}

@immutable
class AiVoicePlaybackState {
  final AiVoiceStatus status;
  final String? currentText;
  final String? currentLanguage;
  final Duration position;
  final Duration duration;
  final String? errorMessage;

  const AiVoicePlaybackState({
    this.status = AiVoiceStatus.idle,
    this.currentText,
    this.currentLanguage,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
  });

  bool get isSpeaking => status == AiVoiceStatus.playing;
  bool get isLoading => status == AiVoiceStatus.loading;
  bool get isPaused => status == AiVoiceStatus.paused;
  bool get hasError => status == AiVoiceStatus.error;

  AiVoicePlaybackState copyWith({
    AiVoiceStatus? status,
    String? currentText,
    String? currentLanguage,
    Duration? position,
    Duration? duration,
    String? errorMessage,
  }) {
    return AiVoicePlaybackState(
      status: status ?? this.status,
      currentText: currentText ?? this.currentText,
      currentLanguage: currentLanguage ?? this.currentLanguage,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AiVoiceService extends StateNotifier<AiVoicePlaybackState> {
  final Ref _ref;
  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription? _playerCompleteSub;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  AiVoiceService(this._ref) : super(const AiVoicePlaybackState()) {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        state = state.copyWith(
          status: AiVoiceStatus.idle,
          position: Duration.zero,
        );
      }
    });

    _playerStateSub = _audioPlayer.onPlayerStateChanged.listen((pState) {
      if (!mounted) return;
      switch (pState) {
        case PlayerState.playing:
          state = state.copyWith(status: AiVoiceStatus.playing);
          break;
        case PlayerState.paused:
          state = state.copyWith(status: AiVoiceStatus.paused);
          break;
        case PlayerState.stopped:
        case PlayerState.completed:
          state = state.copyWith(status: AiVoiceStatus.idle);
          break;
        case PlayerState.disposed:
          state = state.copyWith(status: AiVoiceStatus.idle);
          break;
      }
    });

    _positionSub = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) {
        state = state.copyWith(position: pos);
      }
    });

    _durationSub = _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) {
        state = state.copyWith(duration: dur);
      }
    });
  }

  @override
  void dispose() {
    _playerCompleteSub?.cancel();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Construct the backend TTS URL
  String getTtsUrl(String text, String? language, double speed) {
    final encodedText = Uri.encodeComponent(text);
    final langParam = (language != null && language.isNotEmpty) ? '&language=${Uri.encodeComponent(language)}' : '';
    final speedParam = '&speed=${speed.toStringAsFixed(1)}';
    return '${ApiEndpoints.baseUrl}${ApiEndpoints.voiceTts}?text=$encodedText$langParam$speedParam';
  }

  /// Extract a concise 1-2 sentence voice summary for TTS to prevent listening fatigue,
  /// while keeping the entire response visible on screen.
  static String getVoiceSummary(String text) {
    final clean = text
        .replaceAll(RegExp(r'[*#_`~]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (clean.length <= 160) return clean;

    // Split into sentences
    final sentences = clean.split(RegExp(r'(?<=[.!?\n])\s+'));
    if (sentences.isEmpty) return clean;

    if (sentences.length == 1) {
      return clean.length > 160 ? '${clean.substring(0, 157)}...' : clean;
    }

    final summary = '${sentences[0]} ${sentences[1]}'.trim();
    if (summary.length <= 200) return summary;
    return sentences[0];
  }

  /// Primary play method.
  /// Plays audio via high-performance memory BytesSource with UrlSource streaming fallback.
  Future<void> play({
    required String text,
    String? language,
    bool isVoiceInteraction = false,
    double? speed,
  }) async {
    final settings = _ref.read(aiVoiceSettingsProvider);

    if (!settings.voiceResponsesEnabled) return;
    if (settings.isMuted) return;

    // Voice response is strictly online-only
    final isOnline = _ref.read(connectivityMonitorProvider).isOnline;
    if (!isOnline && !isVoiceInteraction) {
      debugPrint('AiVoiceService: Voice responses are available in online mode only.');
      return;
    }

    final effectiveSpeed = speed ?? settings.speakingSpeed;
    final speechText = getVoiceSummary(text);

    if (speechText.isEmpty) return;

    try {
      // If currently playing, stop before starting new speech
      await _audioPlayer.stop();

      state = state.copyWith(
        status: AiVoiceStatus.loading,
        currentText: speechText,
        currentLanguage: language,
        errorMessage: null,
      );

      final ttsUrl = getTtsUrl(speechText, language, effectiveSpeed);
      debugPrint('AiVoiceService: Requesting audio from $ttsUrl');

      await _audioPlayer.setVolume(1.0);

      // Strategy 1: Fetch bytes directly via Dio and play via BytesSource
      // BytesSource eliminates OS-level audio buffering bugs on Android and Windows
      bool playedViaBytes = false;
      try {
        final dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 8),
        ));
        final response = await dio.get<List<int>>(
          ttsUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null && response.data!.isNotEmpty) {
          final bytes = Uint8List.fromList(response.data!);
          await _audioPlayer.play(BytesSource(bytes));
          playedViaBytes = true;
          debugPrint('AiVoiceService: Playing via BytesSource (${bytes.length} bytes)');
        }
      } catch (dioErr) {
        debugPrint('AiVoiceService: Direct byte fetch failed ($dioErr), falling back to UrlSource');
      }

      // Strategy 2: Fallback to UrlSource
      if (!playedViaBytes) {
        await _audioPlayer.play(UrlSource(ttsUrl));
        debugPrint('AiVoiceService: Playing via UrlSource');
      }

      if (mounted) {
        state = state.copyWith(status: AiVoiceStatus.playing);
      }
    } catch (e) {
      debugPrint('AiVoiceService error: $e');
      if (mounted) {
        state = state.copyWith(
          status: AiVoiceStatus.error,
          errorMessage: "Voice isn't available right now.",
        );
      }
    }
  }

  /// Immediately stops playback. Critical for interrupt handling when user speaks.
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('AiVoiceService stop error: $e');
    }
    if (mounted) {
      state = state.copyWith(
        status: AiVoiceStatus.idle,
        position: Duration.zero,
      );
    }
  }

  /// Pause current playback
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('AiVoiceService pause error: $e');
    }
  }

  /// Resume paused playback
  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('AiVoiceService resume error: $e');
    }
  }

  /// Replay the last played audio
  Future<void> replay() async {
    final lastText = state.currentText;
    if (lastText != null && lastText.isNotEmpty) {
      await play(
        text: lastText,
        language: state.currentLanguage,
        isVoiceInteraction: true,
      );
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause(String text, String? language) async {
    if (state.status == AiVoiceStatus.playing) {
      await pause();
    } else if (state.status == AiVoiceStatus.paused) {
      await resume();
    } else {
      await play(
        text: text,
        language: language,
        isVoiceInteraction: true,
      );
    }
  }
}

final aiVoiceServiceProvider =
    StateNotifierProvider<AiVoiceService, AiVoicePlaybackState>((ref) {
  return AiVoiceService(ref);
});
