import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class AiVoiceSettings {
  final bool voiceResponsesEnabled;
  final bool autoPlayEnabled;
  final String voiceGender; // 'Female'
  final double speakingSpeed; // 0.8, 1.0, 1.2
  final bool isMuted;

  const AiVoiceSettings({
    this.voiceResponsesEnabled = true,
    this.autoPlayEnabled = true,
    this.voiceGender = 'Female',
    this.speakingSpeed = 1.0,
    this.isMuted = false,
  });

  AiVoiceSettings copyWith({
    bool? voiceResponsesEnabled,
    bool? autoPlayEnabled,
    String? voiceGender,
    double? speakingSpeed,
    bool? isMuted,
  }) {
    return AiVoiceSettings(
      voiceResponsesEnabled: voiceResponsesEnabled ?? this.voiceResponsesEnabled,
      autoPlayEnabled: autoPlayEnabled ?? this.autoPlayEnabled,
      voiceGender: voiceGender ?? this.voiceGender,
      speakingSpeed: speakingSpeed ?? this.speakingSpeed,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  Map<String, dynamic> toJson() => {
        'voiceResponsesEnabled': voiceResponsesEnabled,
        'autoPlayEnabled': autoPlayEnabled,
        'voiceGender': voiceGender,
        'speakingSpeed': speakingSpeed,
        'isMuted': isMuted,
      };

  factory AiVoiceSettings.fromJson(Map<String, dynamic> json) {
    return AiVoiceSettings(
      voiceResponsesEnabled: json['voiceResponsesEnabled'] as bool? ?? true,
      autoPlayEnabled: json['autoPlayEnabled'] as bool? ?? true,
      voiceGender: json['voiceGender'] as String? ?? 'Female',
      speakingSpeed: (json['speakingSpeed'] as num?)?.toDouble() ?? 1.0,
      isMuted: json['isMuted'] as bool? ?? false,
    );
  }
}

class AiVoiceSettingsNotifier extends StateNotifier<AiVoiceSettings> {
  AiVoiceSettingsNotifier() : super(const AiVoiceSettings());

  void setVoiceResponsesEnabled(bool enabled) {
    state = state.copyWith(voiceResponsesEnabled: enabled);
  }

  void setAutoPlayEnabled(bool enabled) {
    state = state.copyWith(autoPlayEnabled: enabled);
  }

  void setSpeakingSpeed(double speed) {
    state = state.copyWith(speakingSpeed: speed);
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void setMuted(bool muted) {
    state = state.copyWith(isMuted: muted);
  }

  void resetDefaults() {
    state = const AiVoiceSettings();
  }
}

final aiVoiceSettingsProvider =
    StateNotifierProvider<AiVoiceSettingsNotifier, AiVoiceSettings>((ref) {
  return AiVoiceSettingsNotifier();
});
