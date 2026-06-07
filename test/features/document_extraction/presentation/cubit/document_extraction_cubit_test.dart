import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/document_extraction/domain/repositories/document_extraction_ai_repository.dart';
import 'package:paw_vault/features/document_extraction/domain/services/document_source_picker.dart';
import 'package:paw_vault/features/document_extraction/presentation/cubit/document_extraction_cubit.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';

void main() {
  group('DocumentExtractionCubit', () {
    test('picks a file and surfaces the extracted draft for review', () async {
      final picker = _FakePicker(file: _pickedFile());
      final aiRepository = _FakeAiRepository(draft: _draft());
      final cubit = DocumentExtractionCubit(
        picker: picker,
        aiRepository: aiRepository,
      );
      final states = <DocumentExtractionState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.pickAndExtract(DocumentSource.camera);
      await Future<void>.delayed(Duration.zero);

      expect(picker.requestedSource, DocumentSource.camera);
      expect(aiRepository.mimeType, 'application/pdf');
      expect(aiRepository.byteCount, 3);
      expect(states.map((s) => s.status), [
        DocumentExtractionStatus.picking,
        DocumentExtractionStatus.extracting,
        DocumentExtractionStatus.review,
      ]);
      expect(cubit.state.draft?.detectedType,
          PetDocumentType.vaccinationCertificate);
      expect(cubit.state.pickedFile, isNotNull);
      expect(cubit.state.hasDraft, isTrue);

      await subscription.cancel();
      await cubit.close();
    });

    test('returns to idle without extracting when the picker is cancelled',
        () async {
      final picker = _FakePicker(file: null);
      final aiRepository = _FakeAiRepository(draft: _draft());
      final cubit = DocumentExtractionCubit(
        picker: picker,
        aiRepository: aiRepository,
      );

      await cubit.pickAndExtract(DocumentSource.gallery);

      expect(cubit.state.status, DocumentExtractionStatus.idle);
      expect(aiRepository.callCount, isZero);

      await cubit.close();
    });

    test('emits failure when extraction throws', () async {
      final picker = _FakePicker(file: _pickedFile());
      final aiRepository = _FakeAiRepository(throwsOnExtract: true);
      final cubit = DocumentExtractionCubit(
        picker: picker,
        aiRepository: aiRepository,
      );

      await cubit.pickAndExtract(DocumentSource.file);

      expect(cubit.state.status, DocumentExtractionStatus.failure);
      expect(cubit.state.errorMessage, contains('extract failed'));

      await cubit.close();
    });
  });
}

PickedFile _pickedFile() {
  return PickedFile(
    bytes: Uint8List.fromList([1, 2, 3]),
    fileName: 'vax.pdf',
    extension: 'pdf',
    contentType: 'application/pdf',
  );
}

DocumentExtractionDraft _draft() {
  return const DocumentExtractionDraft(
    requiresConfirmation: true,
    detectedType: PetDocumentType.vaccinationCertificate,
    title: 'Rabies vaccination',
    confidence: 0.9,
  );
}

class _FakePicker implements DocumentSourcePicker {
  _FakePicker({this.file});

  final PickedFile? file;
  DocumentSource? requestedSource;

  @override
  Future<PickedFile?> pick(DocumentSource source) async {
    requestedSource = source;
    return file;
  }
}

class _FakeAiRepository implements DocumentExtractionAiRepository {
  _FakeAiRepository({
    this.draft,
    this.throwsOnExtract = false,
  });

  final DocumentExtractionDraft? draft;
  final bool throwsOnExtract;

  int callCount = 0;
  String? mimeType;
  int? byteCount;

  @override
  Future<DocumentExtractionDraft> extractDocument({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    callCount++;
    this.mimeType = mimeType;
    byteCount = bytes.length;
    if (throwsOnExtract) {
      throw StateError('extract failed');
    }
    return draft!;
  }
}
