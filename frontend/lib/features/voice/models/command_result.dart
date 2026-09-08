import 'voice_models.dart' show VoiceIntentType;

/// The execution outcome of a normalized voice command.
class CommandExecutionResult {
  final bool success;
  final String operationId;
  final VoiceIntentType intent;
  final String message;
  final bool isOffline;
  final String? navigationRoute;
  final String? affectedItemName;
  final double? affectedQuantity;
  final String? affectedUnit;
  final double? previousStock;
  final double? newStock;
  final dynamic payload;

  const CommandExecutionResult({
    required this.success,
    required this.operationId,
    required this.intent,
    required this.message,
    this.isOffline = false,
    this.navigationRoute,
    this.affectedItemName,
    this.affectedQuantity,
    this.affectedUnit,
    this.previousStock,
    this.newStock,
    this.payload,
  });

  factory CommandExecutionResult.success({
    required String operationId,
    required VoiceIntentType intent,
    required String message,
    bool isOffline = false,
    String? navigationRoute,
    String? affectedItemName,
    double? affectedQuantity,
    String? affectedUnit,
    double? previousStock,
    double? newStock,
    dynamic payload,
  }) {
    return CommandExecutionResult(
      success: true,
      operationId: operationId,
      intent: intent,
      message: message,
      isOffline: isOffline,
      navigationRoute: navigationRoute,
      affectedItemName: affectedItemName,
      affectedQuantity: affectedQuantity,
      affectedUnit: affectedUnit,
      previousStock: previousStock,
      newStock: newStock,
      payload: payload,
    );
  }

  factory CommandExecutionResult.failure({
    required String operationId,
    required VoiceIntentType intent,
    required String message,
    bool isOffline = false,
  }) {
    return CommandExecutionResult(
      success: false,
      operationId: operationId,
      intent: intent,
      message: message,
      isOffline: isOffline,
    );
  }
}
