import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/documents/domain/entities/document_attachment.dart';

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
    this.attachments = const [],
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

  /// Files attached to the analysis, for an entry created by scanning a
  /// document. Reuses the documents feature's type rather than duplicating a
  /// two-field value object that would then have to be kept in sync: a
  /// scanned analysis *is* describing a document.
  final List<DocumentAttachment> attachments;

  /// The attached files that can be shown as a thumbnail or preview.
  List<DocumentAttachment> get imageAttachments =>
      attachments.where((attachment) => attachment.isImage).toList();

  final SmartMessageStatus status;
  final UtcDateTime? createdAt;
}
