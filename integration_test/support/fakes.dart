// In-memory repository fakes used only to render screens for App Store
// screenshots. They return seeded data from streams so every screen looks
// populated. No Firebase, no network.
import 'dart:typed_data';

import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/account_auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_data.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_export.dart';
import 'package:paw_vault/features/vet_summary_export/domain/repositories/vet_summary_export_repository.dart';
import 'package:paw_vault/features/vet_summary_export/domain/services/pdf_share_service.dart';
import 'package:paw_vault/features/vet_summary_export/domain/services/vet_summary_pdf_generator.dart';

const _user = AppUser(
  id: 'user-1',
  isAnonymous: false,
  email: 'emma@example.com',
  displayName: 'Emma',
);

class FakeAuthRepository implements AccountAuthRepository {
  @override
  Future<AppUser?> currentUser() async => _user;

  @override
  Future<AppUser> signInAnonymously() async => _user;

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() => Stream<AppUser?>.value(_user);

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  }) async =>
      _user;

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      _user;

  @override
  Future<AppUser> signInWithGoogle() async => _user;

  @override
  Future<AppUser> signInWithApple() async => _user;
}

class FakePetRepository implements PetRepository {
  FakePetRepository(this.pets);

  final List<Pet> pets;

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<Pet>> watchPets(EntityId userId) => Stream<List<Pet>>.value(pets);

  @override
  Future<Pet?> getPet({
    required EntityId userId,
    required EntityId petId,
  }) async =>
      pets.firstWhere((pet) => pet.id == petId, orElse: () => pets.first);

  @override
  Future<void> savePet(Pet pet) async {}

  @override
  Future<void> deletePet({
    required EntityId userId,
    required EntityId petId,
  }) async {}
}

class FakeTimelineRepository implements TimelineRepository {
  FakeTimelineRepository(this.events);

  final List<PetEvent> events;

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PetEvent>> watchEvents({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream<List<PetEvent>>.value(events);

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

class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository(this.documents);

  final List<PetDocument> documents;

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PetDocument>> watchDocuments({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream<List<PetDocument>>.value(documents);

  @override
  Future<PetDocument?> getDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async {
    for (final document in documents) {
      if (document.id == documentId) {
        return document;
      }
    }
    return null;
  }

  @override
  Future<void> saveDocument(PetDocument document) async {}

  @override
  Future<void> deleteDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async {}
}

class FakeReminderRepository implements ReminderRepository {
  FakeReminderRepository(this.reminders);

  final List<Reminder> reminders;

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<Reminder>> watchReminders({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream<List<Reminder>>.value(reminders);

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

class FakeSmartInputRepository implements SmartInputRepository {
  FakeSmartInputRepository(this.messages);

  final List<SmartMessage> messages;

  @override
  Future<SmartInputDraft> createDraft(String input) async =>
      SmartInputDraft(originalText: input, requiresConfirmation: true);

  @override
  Stream<List<SmartMessage>> watchSmartMessages({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream<List<SmartMessage>>.value(messages);

  @override
  Future<SmartMessage?> getSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) async =>
      null;

  @override
  Future<void> saveSmartMessage(SmartMessage message) async {}

  @override
  Future<void> deleteSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) async {}
}

class FakeVetSummaryExportRepository implements VetSummaryExportRepository {
  FakeVetSummaryExportRepository(this.exports);

  final List<VetSummaryExport> exports;

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<VetSummaryExport>> watchExports({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream<List<VetSummaryExport>>.value(exports);

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

class FakeStorageRepository implements StorageRepository {
  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async =>
      StorageFile(
        path: path,
        downloadUrl: Uri.parse('https://example.com/$path'),
      );

  @override
  Future<void> delete(String path) async {}
}

class FakeVetSummaryPdfGenerator implements VetSummaryPdfGenerator {
  @override
  Future<Uint8List> build(VetSummaryData data) async =>
      Uint8List.fromList(<int>[37, 80, 68, 70]);
}

class FakePdfShareService implements PdfShareService {
  @override
  Future<void> share({
    required Uint8List bytes,
    required String fileName,
  }) async {}
}
