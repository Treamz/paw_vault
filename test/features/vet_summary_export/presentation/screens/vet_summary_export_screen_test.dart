import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/analytics/data/services/noop_analytics_service.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
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
import 'package:paw_vault/features/vet_summary_export/presentation/screens/vet_summary_export_screen.dart';

void main() {
  group('VetSummaryExportScreen', () {
    testWidgets('renders the generate action and empty export history',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Generate summary'), findsOneWidget);
      expect(find.text('No saved exports yet.'), findsOneWidget);
    });
  });
}

Widget _app() {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: _FakeAuthRepository()),
      RepositoryProvider<AnalyticsService>.value(
        value: const NoopAnalyticsService(),
      ),
      RepositoryProvider<StorageRepository>.value(
        value: _FakeStorageRepository(),
      ),
      RepositoryProvider<VetSummaryExportRepository>.value(
        value: _FakeExportRepository(),
      ),
      RepositoryProvider<VetSummaryPdfGenerator>.value(
        value: _FakePdfGenerator(),
      ),
      RepositoryProvider<PdfShareService>.value(value: _FakeShareService()),
      RepositoryProvider<LoadVetSummaryData>.value(
        value: LoadVetSummaryData(
          petRepository: _FakePetRepository(),
          timelineRepository: _FakeTimelineRepository(),
          documentRepository: _FakeDocumentRepository(),
          reminderRepository: _FakeReminderRepository(),
        ),
      ),
    ],
    child: const MaterialApp(home: VetSummaryExportScreen(petId: 'pet-1')),
  );
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AppUser?> currentUser() async =>
      const AppUser(id: 'user-1', isAnonymous: true);

  @override
  Future<AppUser> signInAnonymously() async =>
      const AppUser(id: 'user-1', isAnonymous: true);

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() => Stream<AppUser?>.value(
        const AppUser(id: 'user-1', isAnonymous: true),
      );
}

class _FakeExportRepository implements VetSummaryExportRepository {
  @override
  Future<void> initialize() async {}

  @override
  Stream<List<VetSummaryExport>> watchExports({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream<List<VetSummaryExport>>.value(const []);

  @override
  Future<VetSummaryExport?> getExport({
    required EntityId userId,
    required EntityId petId,
    required EntityId exportId,
  }) async =>
      null;

  @override
  Future<void> saveExport(VetSummaryExport summaryExport) async {}

  @override
  Future<void> deleteExport({
    required EntityId userId,
    required EntityId petId,
    required EntityId exportId,
  }) async {}
}

class _FakeStorageRepository implements StorageRepository {
  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async =>
      StorageFile(path: path, downloadUrl: Uri.parse('https://x/$path'));

  @override
  Future<void> delete(String path) async {}
}

class _FakePdfGenerator implements VetSummaryPdfGenerator {
  @override
  Future<Uint8List> build(VetSummaryData data) async =>
      Uint8List.fromList([37, 80, 68, 70]);
}

class _FakeShareService implements PdfShareService {
  @override
  Future<void> share({
    required Uint8List bytes,
    required String fileName,
  }) async {}
}

class _FakePetRepository implements PetRepository {
  @override
  Future<void> initialize() async {}

  @override
  Future<Pet?> getPet({
    required EntityId userId,
    required EntityId petId,
  }) async =>
      const Pet(id: EntityId('pet-1'), userId: EntityId('user-1'), name: 'B');

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
