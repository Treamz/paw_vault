import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/ai/data/datasources/firebase_ai_logic_data_source.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/smart_input/data/repositories/firebase_ready_ai_repository.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';

void main() {
  group('FirebaseReadyAiRepository', () {
    test('structures user input through the data source', () async {
      final draft = _draft('Add rabies vaccine.');
      final dataSource = _FakeFirebaseAiLogicDataSource(userInputDraft: draft);
      final repository = FirebaseReadyAiRepository(dataSource);

      final result = await repository.structureUserInput('Add rabies vaccine.');

      expect(result, draft);
      expect(dataSource.structuredUserInput, 'Add rabies vaccine.');
    });

    test('structures document text through the data source', () async {
      final draft = _draft('Rabies certificate text.');
      final dataSource = _FakeFirebaseAiLogicDataSource(
        documentTextDraft: draft,
      );
      final repository = FirebaseReadyAiRepository(dataSource);

      final result = await repository.structureDocumentText(
        'Rabies certificate text.',
      );

      expect(result, draft);
      expect(dataSource.structuredDocumentText, 'Rabies certificate text.');
    });
  });
}

SmartInputDraft _draft(String originalText) {
  return SmartInputDraft(
    originalText: originalText,
    requiresConfirmation: true,
    detectedIntent: SmartMessageIntent.addVaccination,
    confidence: 0.8,
  );
}

class _FakeFirebaseAiLogicDataSource implements FirebaseAiLogicDataSource {
  _FakeFirebaseAiLogicDataSource({
    SmartInputDraft? userInputDraft,
    SmartInputDraft? documentTextDraft,
  })  : userInputDraft = userInputDraft ?? _draft('user input'),
        documentTextDraft = documentTextDraft ?? _draft('document text');

  final SmartInputDraft userInputDraft;
  final SmartInputDraft documentTextDraft;

  String? structuredUserInput;
  String? structuredDocumentText;

  @override
  Future<SmartInputDraft> structureDocumentText(String text) async {
    structuredDocumentText = text;
    return documentTextDraft;
  }

  @override
  Future<SmartInputDraft> structureUserInput(String input) async {
    structuredUserInput = input;
    return userInputDraft;
  }

  @override
  Future<DocumentExtractionDraft> extractDocument({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    return const DocumentExtractionDraft(requiresConfirmation: true);
  }
}
