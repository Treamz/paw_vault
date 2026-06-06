import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';

enum SmartMessageIntent {
  addAllergy,
  addMedication,
  addVaccination,
  addSymptom,
  addVetVisit,
  addReminder,
  addNote,
  unknown,
}

enum SmartMessageStatus {
  draft,
  awaitingConfirmation,
  confirmed,
  saveFailed,
  dismissed,
}

enum SmartSuggestedActionType {
  updatePetAllergies,
  createTimelineEvent,
  createReminder,
  createDocument,
  updatePetNotes,
  unknown,
}

class SmartSuggestedAction {
  const SmartSuggestedAction({
    required this.type,
    this.payload = const {},
  });

  final SmartSuggestedActionType type;
  final Map<String, Object?> payload;
}

class SmartMessage {
  const SmartMessage({
    required this.id,
    required this.userId,
    required this.petId,
    required this.originalText,
    required this.detectedIntent,
    required this.confidence,
    required this.status,
    this.extractedData = const {},
    this.suggestedActions = const [],
    this.createdAt,
  });

  final EntityId id;
  final EntityId userId;
  final EntityId petId;
  final String originalText;
  final SmartMessageIntent detectedIntent;
  final Map<String, Object?> extractedData;
  final List<SmartSuggestedAction> suggestedActions;
  final double confidence;
  final SmartMessageStatus status;
  final UtcDateTime? createdAt;
}
