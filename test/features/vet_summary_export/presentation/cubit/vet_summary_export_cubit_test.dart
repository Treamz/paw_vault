import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/vet_summary_export/application/load_vet_summary_data.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_data.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_export.dart';
import 'package:paw_vault/features/vet_summary_export/domain/repositories/vet_summary_export_repository.dart';
import 'package:paw_vault/features/vet_summary_export/domain/services/pdf_share_service.dart';
import 'package:paw_vault/features/vet_summary_export/domain/services/vet_summary_pdf_generator.dart';
import 'package:paw_vault/features/vet_summary_export/presentation/cubit/vet_summary_export_cubit.dart';

void main() {
  group('VetSummaryExportCubit', () {
    test('generate loads data, builds a PDF, and holds it', () async {
      final generator = _FakePdfGenerator();
      final cubit = _cubit(pdfGenerator: generator, pet: _pet());

      await cubit.generate('pet-1');

      expect(generator.builtData?.pet.name, 'Bella');
      expect(cubit.state.status, VetSummaryExportStatus.ready);
      expect(cubit.state.hasPdf, isTrue);
      expect(cubit.state.petName, 'Bella');

      await cubit.close();
    });

    test('generate emits failure when the pet is missing', () async {
      final cubit = _cubit(pet: null);

      await cubit.generate('pet-1');

      expect(cubit.state.status, VetSummaryExportStatus.failure);

      await cubit.close();
    });

    test('share sends the generated PDF to the share service', () async {
      final share = _FakeShareService();
      final cubit = _cubit(shareService: share, pet: _pet());

      await cubit.generate('pet-1');
      await cubit.share();

      expect(share.sharedBytes, isNotNull);
      expect(share.sharedFileName, contains('Bella'));
      expect(cubit.state.status, VetSummaryExportStatus.ready);

      await cubit.close();
    });

    test('share fails when nothing has been generated', () async {
      final share = _FakeShareService();
      final cubit = _cubit(shareService: share, pet: _pet());

      await cubit.share();

      expect(cubit.state.status, VetSummaryExportStatus.failure);
      expect(share.sharedBytes, isNull);

      await cubit.close();
    });

    test('saveCopy uploads the PDF and records the export', () async {
      final storage = _FakeStorageRepository();
      final exportRepo = _FakeExportRepository();
      final cubit = _cubit(
        storageRepository: storage,
        exportRepository: exportRepo,
        pet: _pet(),
      );

      await cubit.generate('pet-1');
      await cubit.saveCopy();

      expect(storage.uploadedPath, contains('exports'));
      expect(storage.uploadedContentType, 'application/pdf');
      final saved = exportRepo.savedExport;
      expect(saved, isNotNull);
      expect(saved!.petId, const EntityId('pet-1'));
      expect(saved.storagePath, storage.uploadedPath);
      expect(cubit.state.status, VetSummaryExportStatus.saved);

      await cubit.close();
    });
  });
}

VetSummaryExportCubit _cubit({
  required Pet? pet,
  _FakePdfGenerator? pdfGenerator,
  _FakeShareService? shareService,
  _FakeStorageRepository? storageRepository,
  _FakeExportRepository? exportRepository,
}) {
  return VetSummaryExportCubit(
    authRepository: _FakeAuthRepository(
      currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
    ),
    loadVetSummaryData: LoadVetSummaryData(
      petRepository: _FakePetRepository(pet: pet),
      timelineRepository: _FakeTimelineRepository(),
      documentRepository: _FakeDocumentRepository(),
      reminderRepository: _FakeReminderRepository(),
    ),
    pdfGenerator: pdfGenerator ?? _FakePdfGenerator(),
    shareService: shareService ?? _FakeShareService(),
    storageRepository: storageRepository ?? _FakeStorageRepository(),
    exportRepository: exportRepository ?? _FakeExportRepository(),
  );
}

Pet _pet() => const Pet(
      id: EntityId('pet-1'),
      userId: EntityId('user-1'),
      name: 'Bella',
    );

class _FakePdfGenerator implements VetSummaryPdfGenerator {
  VetSummaryData? builtData;

  @override
  Future<Uint8List> build(VetSummaryData data) async {
    builtData = data;
    return Uint8List.fromList([37, 80, 68, 70]); // %PDF
  }
}

class _FakeShareService implements PdfShareService {
  Uint8List? sharedBytes;
  String? sharedFileName;

  @override
  Future<void> share({
    required Uint8List bytes,
    required String fileName,
  }) async {
    sharedBytes = bytes;
    sharedFileName = fileName;
  }
}

class _FakeStorageRepository implements StorageRepository {
  String? uploadedPath;
  String? uploadedContentType;

  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadedPath = path;
    uploadedContentType = contentType;
    return StorageFile(
      path: path,
      downloadUrl: Uri.parse('https://storage.example.com/$path'),
    );
  }

  @override
  Future<void> delete(String path) async {}
}

class _FakeExportRepository implements VetSummaryExportRepository {
  VetSummaryExport? savedExport;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveExport(VetSummaryExport summaryExport) async {
    savedExport = summaryExport;
  }

  @override
  Stream<List<VetSummaryExport>> watchExports({
    required EntityId userId,
    required EntityId petId,
  }) =>
      const Stream<List<VetSummaryExport>>.empty();

  @override
  Future<VetSummaryExport?> getExport({
    required EntityId userId,
    required EntityId petId,
    required EntityId exportId,
  }) async =>
      null;

  @override
  Future<void> deleteExport({
    required EntityId userId,
    required EntityId petId,
    required EntityId exportId,
  }) async {}
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.currentUserValue});

  final AppUser? currentUserValue;

  @override
  Future<AppUser?> currentUser() async => currentUserValue;

  @override
  Future<AppUser> signInAnonymously() async =>
      const AppUser(id: 'signed-in-user', isAnonymous: true);

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() =>
      Stream<AppUser?>.value(currentUserValue);
}

class _FakePetRepository implements PetRepository {
  _FakePetRepository({this.pet});

  final Pet? pet;

  @override
  Future<void> initialize() async {}

  @override
  Future<Pet?> getPet({
    required EntityId userId,
    required EntityId petId,
  }) async =>
      pet;

  @override
  Stream<List<Pet>> watchPets(EntityId userId) =>
      const Stream<List<Pet>>.empty();

  @override
  Future<void> savePet(Pet pet) async {}

  @override
  Future<void> deletePet({
    required EntityId userId,
    required EntityId petId,
  }) async {}
}

class _FakeTimelineRepository implements TimelineRepository {
  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PetEvent>> watchEvents({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream<List<PetEvent>>.value(const []);

  @override
  Future<PetEvent?> getEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async =>
      null;

  @override
  Future<void> saveEvent(PetEvent event) async {}

  @override
  Future<void> deleteEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async {}
}

class _FakeDocumentRepository implements DocumentRepository {
  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PetDocument>> watchDocuments({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream<List<PetDocument>>.value(const []);

  @override
  Future<PetDocument?> getDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async =>
      null;

  @override
  Future<void> saveDocument(PetDocument document) async {}

  @override
  Future<void> deleteDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async {}
}

class _FakeReminderRepository implements ReminderRepository {
  @override
  Future<void> initialize() async {}

  @override
  Stream<List<Reminder>> watchReminders({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream<List<Reminder>>.value(const []);

  @override
  Future<Reminder?> getReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async =>
      null;

  @override
  Future<void> saveReminder(Reminder reminder) async {}

  @override
  Future<void> completeReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async {}

  @override
  Future<void> deleteReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async {}
}
