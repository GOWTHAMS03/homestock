import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_providers.dart' show connectivityMonitorProvider;
import '../controllers/voice_controller.dart' show voiceRepositoryProvider, commandExecutorProvider;
import '../data/voice_repository.dart';
import '../domain/command_executor.dart';
import '../models/voice_models.dart';

final voiceAiServiceProvider = Provider<VoiceAiService>((ref) {
  final repo = ref.watch(voiceRepositoryProvider);
  final executor = ref.watch(commandExecutorProvider);
  final connectivity = ref.watch(connectivityMonitorProvider);

  return VoiceAiService(
    voiceRepository: repo,
    localExecutor: executor,
    isOnline: connectivity.isOnline,
  );
});

class VoiceAiService {
  final VoiceRepository? voiceRepository;
  final CommandExecutor? localExecutor;
  final bool isOnline;

  VoiceAiService({
    this.voiceRepository,
    this.localExecutor,
    this.isOnline = true,
  });

  String generateIdempotencyKey() {
    final rand = Random().nextInt(999999);
    return 'voice-${DateTime.now().millisecondsSinceEpoch}-$rand';
  }

  /// Process spoken voice recording with Gemini Flash-Lite multimodal pipeline
  Future<VoiceCommandResult> processAudioCommand({
    required String audioFilePath,
    required String homeId,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? generateIdempotencyKey();

    if (isOnline && voiceRepository != null) {
      try {
        final result = await voiceRepository!.processAiAudio(
          audioFilePath,
          homeId,
          idempotencyKey: key,
        );
        return result;
      } catch (e) {
        debugPrint('Gemini Voice AI endpoint failed: $e, checking fallback');
        // If server failed or network dropped mid-call, fall back to legacy/local
      }
    }

    // Offline or fallback handling
    return VoiceCommandResult(
      transcript: '',
      intent: VoiceIntentType.unknown,
      confidence: 0.0,
      requiresConfirmation: false,
      message: 'Network offline. Voice processing requires an internet connection.',
    );
  }

  /// Process text command through Gemini Voice AI
  Future<VoiceCommandResult> processTextCommand({
    required String transcript,
    required String homeId,
  }) async {
    if (isOnline && voiceRepository != null) {
      return await voiceRepository!.parseAiCommand(transcript, homeId);
    }

    return VoiceCommandResult(
      transcript: transcript,
      intent: VoiceIntentType.unknown,
      confidence: 0.0,
      requiresConfirmation: false,
      message: 'Network offline. Please check your connection.',
    );
  }

  /// Follow-up on a multi-turn conversation (e.g. providing quantity or choosing product)
  Future<VoiceCommandResult> processFollowUp({
    required String transcript,
    required String homeId,
  }) async {
    if (isOnline && voiceRepository != null) {
      return await voiceRepository!.followUpAiCommand(transcript, homeId);
    }

    return VoiceCommandResult(
      transcript: transcript,
      intent: VoiceIntentType.unknown,
      confidence: 0.0,
      requiresConfirmation: false,
      message: 'Follow-up requires active network connection.',
    );
  }

  /// Execute validated voice command against backend
  Future<ExecuteCommandResponse> executeCommand({
    required String homeId,
    required VoiceCommandResult commandResult,
    bool confirmed = true,
    String? selectedOptionId,
    String? idempotencyKey,
  }) async {
    final request = ExecuteCommandRequest(
      homeId: homeId,
      commandResult: commandResult,
      confirmed: confirmed,
      selectedOptionId: selectedOptionId,
      idempotencyKey: idempotencyKey ?? commandResult.idempotencyKey,
    );

    if (voiceRepository != null) {
      return await voiceRepository!.executeCommand(request);
    }

    return const ExecuteCommandResponse(
      success: false,
      intent: VoiceIntentType.unknown,
      message: 'Voice repository unavailable.',
    );
  }

  /// Determines if command can be executed immediately without extra user confirmation
  bool canAutoExecute(VoiceCommandResult result) {
    if (result.intent == VoiceIntentType.unknown) return false;
    if (result.requiresConfirmation) return false;
    if (result.quantityConfirmation != null) return false;
    if (result.executionStatus == 'NEEDS_QUANTITY_CONFIRMATION') return false;
    if (result.needsQuantity || result.needsProduct) return false;
    if (result.disambiguationOptions.isNotEmpty) return false;
    if (result.intent == VoiceIntentType.clearShoppingList) return false;

    // Adding items to shopping list and search operations are safe and should auto-execute immediately
    if (result.intent == VoiceIntentType.addShoppingItem ||
        result.intent == VoiceIntentType.searchInventory ||
        result.intent == VoiceIntentType.searchProduct) {
      return result.intentConfidence >= 0.70;
    }

    // Dual confidence criteria for inventory and other modifications
    return result.intentConfidence >= 0.80 && result.productMatchConfidence >= 0.80;
  }
}

