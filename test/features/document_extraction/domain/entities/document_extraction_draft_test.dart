import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';

void main() {
  group('DocumentExtractionDraft', () {
    test('defaults optional fields to null', () {
      const draft = DocumentExtractionDraft(requiresConfirmation: true);

      expect(draft.detectedType, isNull);
      expect(draft.title, isNull);
      expect(draft.issueDate, isNull);
      expect(draft.expiryDate, isNull);
      expect(draft.notes, isNull);
      expect(draft.extractedText, isNull);
      expect(draft.confidence, isNull);
      expect(draft.requiresConfirmation, isTrue);
    });

    test('holds the suggested fields', () {
      const draft = DocumentExtractionDraft(
        requiresConfirmation: true,
        detectedType: PetDocumentType.vaccinationCertificate,
        title: 'Rabies vaccination',
        issueDate: DateOnly(year: 2026, month: 1, day: 10),
        expiryDate: DateOnly(year: 2027, month: 1, day: 10),
        notes: 'Annual booster',
        extractedText: 'Rabies vaccine administered 2026-01-10',
        confidence: 0.88,
      );

      expect(draft.detectedType, PetDocumentType.vaccinationCertificate);
      expect(draft.title, 'Rabies vaccination');
      expect(draft.issueDate, const DateOnly(year: 2026, month: 1, day: 10));
      expect(draft.expiryDate, const DateOnly(year: 2027, month: 1, day: 10));
      expect(draft.notes, 'Annual booster');
      expect(draft.extractedText, contains('Rabies'));
      expect(draft.confidence, 0.88);
    });

    test('isLowConfidence reflects the confidence threshold', () {
      const low =
          DocumentExtractionDraft(requiresConfirmation: true, confidence: 0.4);
      const high =
          DocumentExtractionDraft(requiresConfirmation: true, confidence: 0.9);
      const unknown = DocumentExtractionDraft(requiresConfirmation: true);

      expect(low.isLowConfidence, isTrue);
      expect(high.isLowConfidence, isFalse);
      expect(unknown.isLowConfidence, isFalse);
    });
  });
}
