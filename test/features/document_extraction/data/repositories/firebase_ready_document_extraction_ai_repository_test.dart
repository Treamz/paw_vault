import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/ai/data/datasources/firebase_ai_logic_data_source.dart';
import 'package:paw_vault/core/ai/data/datasources/noop_firebase_ai_logic_data_source.dart';
import 'package:paw_vault/features/document_extraction/data/repositories/firebase_ready_document_extraction_ai_repository.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';

void main() {
  group('FirebaseReadyDocumentExtractionAiRepository', () {
    test('delegates extraction to the AI data source', () async {
      final dataSource = _FakeAiDataSource();
      final repository =
          FirebaseReadyDocumentExtractionAiRepository(dataSource);

      final draft = await repository.extractDocument(
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'application/pdf',
      );

      expect(dataSource.extractMimeType, 'application/pdf');
      expect(dataSource.extractByteCount, 3);
      expect(draft.detectedType, PetDocumentType.vaccinationCertificate);
      expect(draft.requiresConfirmation, isTrue);
    });
  });

  group('NoopFirebaseAiLogicDataSource', () {
    test('returns a confirmation-required draft without classification',
        () async {
      final dataSource = NoopFirebaseAiLogicDataSource();

      final draft = await dataSource.extractDocument(
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/jpeg',
      );

      expect(draft.requiresConfirmation, isTrue);
      expect(draft.detectedType, isNull);
    });
  });
}

class _FakeAiDataSource implements FirebaseAiLogicDataSource {
  String? extractMimeType;
  int? extractByteCount;

  @override
  Future<DocumentExtractionDraft> extractDocument({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    extractMimeType = mimeType;
    extractByteCount = bytes.length;
    return const DocumentExtractionDraft(
      requiresConfirmation: true,
      detectedType: PetDocumentType.vaccinationCertificate,
      confidence: 0.9,
    );
  }

  @override
  Future<SmartInputDraft> structureDocumentText(String text) {
    throw UnimplementedError();
  }

  @override
  Future<SmartInputDraft> structureUserInput(String input) {
    throw UnimplementedError();
  }
}
