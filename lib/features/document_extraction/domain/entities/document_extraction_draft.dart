import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';

/// AI-suggested structured fields extracted from a document file.
///
/// This is a draft only — it is shown to the user in a pre-filled, editable
/// form and is never persisted without explicit confirmation.
class DocumentExtractionDraft {
  const DocumentExtractionDraft({
    required this.requiresConfirmation,
    this.detectedType,
    this.title,
    this.issueDate,
    this.expiryDate,
    this.notes,
    this.extractedText,
    this.confidence,
  });

  /// The document type the AI believes this file is.
  final PetDocumentType? detectedType;

  /// A suggested human-readable title for the document.
  final String? title;

  final DateOnly? issueDate;
  final DateOnly? expiryDate;
  final String? notes;

  /// Raw text the AI read from the file, if any.
  final String? extractedText;

  /// Model confidence in the extraction, in the range 0..1.
  final double? confidence;

  /// Always true — extracted data must be reviewed before saving.
  final bool requiresConfirmation;

  bool get isLowConfidence => confidence != null && confidence! < 0.6;
}
