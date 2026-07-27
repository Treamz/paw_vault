import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:paw_vault/core/ai/data/datasources/firebase_ai_logic_data_source.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';

class FlutterFireAiLogicDataSource implements FirebaseAiLogicDataSource {
  const FlutterFireAiLogicDataSource(
    this._firebaseAi, {
    this.modelName = 'gemini-2.5-flash',
  });

  final FirebaseAI _firebaseAi;
  final String modelName;

  @override
  Future<SmartInputDraft> structureDocumentText(String text) =>
      structureUserInput(text);

  @override
  Future<SmartInputDraft> structureUserInput(String input) async {
    final model = _createModel();
    final response = await model.generateContent([
      Content.text('$_smartInputPrompt\n\nUser note:\n$input'),
    ]);
    return parseSmartInputDraft(response.text, originalText: input);
  }

  static const _smartInputPrompt = '''
The user wrote a short note about their pet's health. Structure it and return
ONLY a JSON object with these keys:
- "intent": one of addAllergy, addMedication, addVaccination, addSymptom,
  addVetVisit, addReminder, addNote, unknown
- "extractedData": an object containing only details the note actually
  mentions (e.g. "medication", "dose", "date", "allergen", "symptom",
  "clinic")
- "suggestedActions": an array with any of updatePetAllergies,
  createTimelineEvent, createReminder, createDocument, updatePetNotes
- "confidence": a number between 0 and 1
Do not diagnose or give medical advice. Only structure what the user wrote.
''';

  /// Parses the model's JSON reply into a review-only draft. Unparseable
  /// output falls back to just the original text flagged for low-confidence
  /// review — the AI never produces anything that saves without confirmation.
  @visibleForTesting
  static SmartInputDraft parseSmartInputDraft(
    String? text, {
    required String originalText,
  }) {
    SmartInputDraft fallback() => SmartInputDraft(
          originalText: originalText,
          requiresConfirmation: true,
          status: SmartInputDraftStatus.lowConfidenceReview,
        );

    if (text == null || text.trim().isEmpty) {
      return fallback();
    }

    try {
      final cleaned =
          text.replaceAll('```json', '').replaceAll('```', '').trim();
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final confidence = (json['confidence'] as num?)?.toDouble();
      final extracted = json['extractedData'];
      final actions = json['suggestedActions'];

      return SmartInputDraft(
        originalText: originalText,
        requiresConfirmation: true,
        detectedIntent: _parseIntent(json['intent'] as String?),
        extractedData:
            extracted is Map ? extracted.cast<String, Object?>() : const {},
        suggestedActions: [
          if (actions is List)
            for (final action in actions)
              SmartSuggestedAction(type: _parseActionType('$action')),
        ],
        confidence: confidence,
        status: confidence != null && confidence < 0.6
            ? SmartInputDraftStatus.lowConfidenceReview
            : SmartInputDraftStatus.awaitingReview,
      );
    } catch (_) {
      return fallback();
    }
  }

  static SmartMessageIntent _parseIntent(String? value) {
    if (value == null) return SmartMessageIntent.unknown;
    for (final intent in SmartMessageIntent.values) {
      if (intent.name.toLowerCase() == value.toLowerCase()) {
        return intent;
      }
    }
    return SmartMessageIntent.unknown;
  }

  static SmartSuggestedActionType _parseActionType(String value) {
    for (final type in SmartSuggestedActionType.values) {
      if (type.name.toLowerCase() == value.toLowerCase()) {
        return type;
      }
    }
    return SmartSuggestedActionType.unknown;
  }

  @override
  Future<DocumentExtractionDraft> extractDocument({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final model = _createModel();
    final response = await model.generateContent([
      Content.multi([
        InlineDataPart(mimeType, bytes),
        const TextPart(_extractionPrompt),
      ]),
    ]);
    return _parseExtractionDraft(response.text);
  }

  static const _extractionPrompt = '''
This is a pet's document (image or PDF). Read it and return ONLY a JSON object
with these keys:
- "type": one of passport, vaccinationCertificate, insurance, labResult,
  prescription, receipt, vetReport, other
- "title": a short human-readable title
- "issueDate": the issue date as "YYYY-MM-DD" or null
- "expiryDate": the expiry date as "YYYY-MM-DD" or null
- "notes": a brief plain-text summary
- "confidence": a number between 0 and 1
Do not diagnose or give medical advice. Only structure what the document says.
''';

  DocumentExtractionDraft _parseExtractionDraft(String? text) {
    if (text == null || text.trim().isEmpty) {
      return const DocumentExtractionDraft(requiresConfirmation: true);
    }

    try {
      final cleaned =
          text.replaceAll('```json', '').replaceAll('```', '').trim();
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return DocumentExtractionDraft(
        requiresConfirmation: true,
        detectedType: _parseType(json['type'] as String?),
        title: json['title'] as String?,
        issueDate: _parseDate(json['issueDate'] as String?),
        expiryDate: _parseDate(json['expiryDate'] as String?),
        notes: json['notes'] as String?,
        extractedText: text,
        confidence: (json['confidence'] as num?)?.toDouble(),
      );
    } catch (_) {
      // Unparseable response — keep the raw text for the user to work from.
      return DocumentExtractionDraft(
        requiresConfirmation: true,
        extractedText: text,
      );
    }
  }

  PetDocumentType? _parseType(String? value) {
    if (value == null) return null;
    for (final type in PetDocumentType.values) {
      if (type.name.toLowerCase() == value.toLowerCase()) {
        return type;
      }
    }
    return null;
  }

  DateOnly? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    return parsed != null ? DateOnly.fromDateTime(parsed) : null;
  }

  GenerativeModel _createModel() {
    return _firebaseAi.generativeModel(
      model: modelName,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
      systemInstruction: Content.system(
        'Structure user-provided pet health data only. Do not diagnose, '
        'recommend treatment, or save data directly. Return draft data that '
        'the app must show for user confirmation before saving.',
      ),
    );
  }
}
