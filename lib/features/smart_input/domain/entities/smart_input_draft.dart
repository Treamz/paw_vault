import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';

enum SmartInputDraftStatus {
  awaitingReview,
  lowConfidenceReview,
  confirmed,
  dismissed,
}

class SmartInputDraft {
  const SmartInputDraft({
    required this.originalText,
    required this.requiresConfirmation,
    this.detectedIntent = SmartMessageIntent.unknown,
    this.extractedData = const {},
    this.suggestedActions = const [],
    this.confidence,
    this.status = SmartInputDraftStatus.awaitingReview,
  });

  final String originalText;
  final bool requiresConfirmation;
  final SmartMessageIntent detectedIntent;
  final Map<String, Object?> extractedData;
  final List<SmartSuggestedAction> suggestedActions;
  final double? confidence;
  final SmartInputDraftStatus status;
}
