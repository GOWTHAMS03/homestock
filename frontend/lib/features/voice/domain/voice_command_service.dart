import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../inventory/inventory_repository.dart';
import '../../shopping/shopping_repository.dart';
import '../data/parser/command_parser.dart';
import '../data/parser/product_resolver.dart';
import '../data/speech/hybrid_speech_engine.dart';
import '../models/command_result.dart';
import '../models/normalized_voice_command.dart';
import '../models/voice_models.dart' show VoiceIntentType;
import '../models/voice_transcript.dart';
import 'command_executor.dart';
import 'command_validator.dart';

/// Conversation turn context for multi-turn clarification (e.g. "Rice add pannu" -> "2 kilo")
class VoiceConversationContext {
  final String? lastProduct;
  final VoiceIntentType? lastIntent;
  final DateTime timestamp;

  const VoiceConversationContext({
    this.lastProduct,
    this.lastIntent,
    required this.timestamp,
  });

  bool get isExpired => DateTime.now().difference(timestamp).inSeconds > 45;
}

/// Orchestrates the full voice command processing pipeline:
/// Record -> Hybrid ASR -> Normalize & Parse -> Context Merge -> Validate -> Execute -> Feedback
class VoiceCommandService {
  final HybridSpeechEngine _speechEngine;
  final CommandExecutor _executor;
  final InventoryRepository _inventoryRepo;
  final ShoppingRepository _shoppingRepo;

  VoiceConversationContext? _context;

  VoiceCommandService({
    required HybridSpeechEngine speechEngine,
    required CommandExecutor executor,
    required InventoryRepository inventoryRepo,
    required ShoppingRepository shoppingRepo,
  })  : _speechEngine = speechEngine,
        _executor = executor,
        _inventoryRepo = inventoryRepo,
        _shoppingRepo = shoppingRepo;

  /// Transcribes the recorded audio file using hybrid ASR (with privacy deletion)
  Future<VoiceTranscript> transcribeAudio(
    String audioFilePath, {
    String? languageHint,
  }) async {
    try {
      final transcript = await _speechEngine.transcribe(
        audioFilePath,
        languageHint: languageHint,
      );
      return transcript;
    } finally {
      // Privacy requirement: Clean up raw audio file immediately
      _deleteAudioQuietly(audioFilePath);
    }
  }

  /// Parses text into a normalized command with local household context
  Future<NormalizedVoiceCommand> parseTranscript({
    required String rawText,
    required String homeId,
    bool isOffline = false,
    String? selectedUiProduct,
  }) async {
    // 1. Fetch local inventory candidates for product resolution
    final invItems = await _inventoryRepo.getItems(homeId);
    final inventoryCandidates = invItems
        .map((i) => ProductCandidate(
              id: i.id,
              name: i.name,
              category: i.categoryName,
              unit: i.unit,
              source: 'INVENTORY',
            ))
        .toList();

    // 2. Fetch active shopping list candidates
    final shoppingList = await _shoppingRepo.getDefaultList(homeId);
    final shoppingCandidates = (shoppingList?.items ?? [])
        .map((i) => ProductCandidate(
              id: i.id,
              name: i.itemName,
              category: i.categoryName ?? 'General',
              unit: i.unit,
              source: 'SHOPPING',
            ))
        .toList();

    // 3. Multi-turn context merging
    String effectiveText = rawText.trim();
    if (_context != null && !_context!.isExpired) {
      // If user is just answering quantity/unit (e.g. "2 kilo" or "one litre")
      final isShortQuantityAnswer = RegExp(r'^(?:\d+(?:\.\d+)?|half|one|two|three|rendu|oru|moonu|arai)\s*(?:kg|kilo|litre|litres|liter|g|packet|bottle|pcs)?$', caseSensitive: false).hasMatch(effectiveText);
      if (isShortQuantityAnswer && _context!.lastProduct != null) {
        effectiveText = '$effectiveText ${_context!.lastProduct!} add pannu';
        debugPrint('[VoiceCommandService] Multi-turn context merged: "$effectiveText"');
      }
    } else if (selectedUiProduct != null && selectedUiProduct.isNotEmpty) {
      // Context from currently selected product on screen
      if (RegExp(r'^(?:\d+(?:\.\d+)?|half|one|two|three|rendu|oru|moonu|arai)\s*(?:kg|kilo|litre|litres|liter|g|packet|bottle|pcs)?\s*(?:add|podu)?$', caseSensitive: false).hasMatch(effectiveText)) {
        effectiveText = '$effectiveText $selectedUiProduct add pannu';
        debugPrint('[VoiceCommandService] Screen context merged: "$effectiveText"');
      }
    }

    // 4. Deterministic Parse
    final command = CommandParser.parse(
      effectiveText,
      userInventory: inventoryCandidates,
      userShoppingList: shoppingCandidates,
      isOffline: isOffline,
    );

    // 5. Update context memory if question asked
    if (command.requiresConfirmation || command.quantity == null) {
      _context = VoiceConversationContext(
        lastProduct: command.productName,
        lastIntent: command.intent,
        timestamp: DateTime.now(),
      );
    } else {
      _context = null; // Clear on successful full command
    }

    return command;
  }

  /// Validates the command
  CommandValidationResult validateCommand(NormalizedVoiceCommand command) {
    return CommandValidator.validate(command);
  }

  /// Executes the command locally through Drift SQLite and Sync Queue
  Future<CommandExecutionResult> executeCommand({
    required NormalizedVoiceCommand command,
    required String homeId,
    String? selectedOptionId,
  }) async {
    final result = await _executor.execute(
      command: command,
      homeId: homeId,
      selectedOptionId: selectedOptionId,
    );

    // Clear multi-turn context on execution
    _context = null;

    return result;
  }

  void _deleteAudioQuietly(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }
}
