import '../models/normalized_voice_command.dart';
import '../models/voice_models.dart' show VoiceIntentType;

class CommandValidationResult {
  final bool isValid;
  final bool canAutoExecute;
  final String? promptMessage;

  const CommandValidationResult({
    required this.isValid,
    required this.canAutoExecute,
    this.promptMessage,
  });

  factory CommandValidationResult.autoExecute() {
    return const CommandValidationResult(
      isValid: true,
      canAutoExecute: true,
    );
  }

  factory CommandValidationResult.requiresConfirmation(String message) {
    return CommandValidationResult(
      isValid: true,
      canAutoExecute: false,
      promptMessage: message,
    );
  }

  factory CommandValidationResult.invalid(String message) {
    return CommandValidationResult(
      isValid: false,
      canAutoExecute: false,
      promptMessage: message,
    );
  }
}

/// Validates normalized commands against safety, confidence, and confirmation rules.
class CommandValidator {
  static CommandValidationResult validate(NormalizedVoiceCommand command) {
    // 1. Unknown or empty commands
    if (command.intent == VoiceIntentType.unknown) {
      return CommandValidationResult.invalid(
        "Sorry, I couldn't understand that command. Please try speaking again.",
      );
    }

    // 2. Very low confidence
    if (command.confidence < 0.60) {
      return CommandValidationResult.invalid(
        "I couldn't hear clearly. Did you mean to add ${command.productName}?",
      );
    }

    // 3. Ambiguous products (must ask user)
    if (command.disambiguationOptions.isNotEmpty) {
      return CommandValidationResult.requiresConfirmation(
        command.confirmationMessage ?? 'Which ${command.productName} do you mean?',
      );
    }

    // 4. Destructive commands (clear shopping list)
    if (command.intent == VoiceIntentType.clearShoppingList) {
      return CommandValidationResult.requiresConfirmation(
        'Clear all items from your shopping list?',
      );
    }

    // 5. Potentially dangerous / large quantity (e.g. 50 kg)
    if (command.quantity != null && command.quantity! >= 50) {
      return CommandValidationResult.requiresConfirmation(
        'Add ${command.quantity} ${command.unit ?? ''} ${command.productName}? That is a large quantity.',
      );
    }

    // 6. Explicitly required confirmation (e.g. unit incompatibility)
    if (command.requiresConfirmation) {
      return CommandValidationResult.requiresConfirmation(
        command.confirmationMessage ?? 'Confirm action for ${command.productName}?',
      );
    }

    // 7. Navigation or query commands auto-execute immediately
    if (command.intent == VoiceIntentType.openShoppingList ||
        command.intent == VoiceIntentType.openInventory ||
        command.intent == VoiceIntentType.openAnalytics ||
        command.intent == VoiceIntentType.startShoppingMode ||
        command.intent == VoiceIntentType.getShoppingList ||
        command.intent == VoiceIntentType.getLowStockItems ||
        command.intent == VoiceIntentType.getOutOfStockItems ||
        command.intent == VoiceIntentType.getExpiringItems ||
        command.intent == VoiceIntentType.getItemStatus ||
        command.intent == VoiceIntentType.whatDoINeed ||
        command.intent == VoiceIntentType.smartPriceCheck) {
      return CommandValidationResult.autoExecute();
    }

    // 8. Normal mutations with high confidence auto-execute immediately
    if (command.confidence >= 0.82) {
      return CommandValidationResult.autoExecute();
    }

    // Borderline confidence: ask confirmation
    return CommandValidationResult.requiresConfirmation(
      command.confirmationMessage ?? 'Add ${command.quantity ?? 1} ${command.unit ?? ''} ${command.productName}?',
    );
  }
}
