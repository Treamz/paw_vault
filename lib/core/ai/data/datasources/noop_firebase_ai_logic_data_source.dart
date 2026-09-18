import 'package:paw_vault/core/ai/data/datasources/firebase_ai_logic_data_source.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_page.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_photo.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_scan_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';

class NoopFirebaseAiLogicDataSource implements FirebaseAiLogicDataSource {
  @override
  Future<SmartInputDraft> structureDocumentText(String text) async {
    return SmartInputDraft(
      originalText: text,
      requiresConfirmation: true,
    );
  }

  @override
  Future<SmartInputDraft> structureUserInput(String input) async {
    return SmartInputDraft(
      originalText: input,
      requiresConfirmation: true,
    );
  }

  @override
  Future<DocumentExtractionDraft> extractDocument({
    required List<DocumentPage> pages,
  }) async {
    return const DocumentExtractionDraft(requiresConfirmation: true);
  }

  /// Local-first mode has no model, so it reports the photo as unreadable
  /// rather than returning an attention level. A fabricated health signal
  /// would be worse than no feature at all.
  @override
  Future<PawScanDraft> analyzePaw({
    required List<PawPhoto> photos,
    required PawLocation location,
    String? speciesLabel,
  }) async {
    return const PawScanDraft.unusable(
      photoQuality: PawScanPhotoQuality.usable,
    );
  }
}
