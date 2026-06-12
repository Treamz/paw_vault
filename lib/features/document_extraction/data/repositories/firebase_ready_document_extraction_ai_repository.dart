import 'dart:typed_data';

import 'package:paw_vault/core/ai/data/datasources/firebase_ai_logic_data_source.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/document_extraction/domain/repositories/document_extraction_ai_repository.dart';

class FirebaseReadyDocumentExtractionAiRepository
    implements DocumentExtractionAiRepository {
  const FirebaseReadyDocumentExtractionAiRepository(this._dataSource);

  final FirebaseAiLogicDataSource _dataSource;

  @override
  Future<DocumentExtractionDraft> extractDocument({
    required Uint8List bytes,
    required String mimeType,
  }) {
    return _dataSource.extractDocument(bytes: bytes, mimeType: mimeType);
  }
}
