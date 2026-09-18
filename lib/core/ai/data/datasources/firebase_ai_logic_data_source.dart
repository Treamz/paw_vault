import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_page.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_photo.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_scan_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';

abstract interface class FirebaseAiLogicDataSource {
  Future<SmartInputDraft> structureUserInput(String input);

  Future<SmartInputDraft> structureDocumentText(String text);

  /// Analyzes all [pages] of a document (images or PDF) together and returns
  /// suggested structured fields as a draft for user review. Never persists
  /// anything.
  Future<DocumentExtractionDraft> extractDocument({
    required List<DocumentPage> pages,
  });

  /// Describes what is visible in [photos] of a pet's paw and returns a
  /// review-only draft. Never diagnoses, never recommends treatment, and
  /// never persists anything.
  Future<PawScanDraft> analyzePaw({
    required List<PawPhoto> photos,
    required PawLocation location,
    String? speciesLabel,
  });
}
