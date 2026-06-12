import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/vet_summary_export/application/load_vet_summary_data.dart';

void main() {
  group('LoadVetSummaryData', () {
    test('aggregates the pet profile, events, documents, and reminders',
        () async {
      final loader = LoadVetSummaryData(
        petRepository: _FakePetRepository(pet: _pet()),
        timelineRepository: _FakeTimelineRepository(events: [_event()]),
        documentRepository: _FakeDocumentRepository(documents: [_document()]),
        reminderRepository: _FakeReminderRepository(reminders: [_reminder()]),
      );

      final data = await loader.call(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
      );

      expect(data.pet.name, 'Bella');
      expect(data.events, hasLength(1));
      expect(data.documents, hasLength(1));
      expect(data.reminders, hasLength(1));
      expect(data.hasRecords, isTrue);
    });

    test('throws when the pet does not exist', () async {
      final loader = LoadVetSummaryData(
        petRepository: _FakePetRepository(pet: null),
        timelineRepository: _FakeTimelineRepository(),
        documentRepository: _FakeDocumentRepository(),
        reminderRepository: _FakeReminderRepository(),
      );

      expect(
        () => loader.call(
          userId: const EntityId('user-1'),
          petId: const EntityId('missing'),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

Pet _pet() => const Pet(
      id: EntityId('pet-1'),
      userId: EntityId('user-1'),
      name: 'Bella',
    );

PetEvent _event() => PetEvent(
      id: const EntityId('event-1'),
      userId: const EntityId('user-1'),
      petId: const EntityId('pet-1'),
      type: PetEventType.vaccination,
      title: 'Rabies',
      date: UtcDateTime(DateTime.utc(2026, 1, 1)),
      source: PetEventSource.manual,
    );

PetDocument _document() => PetDocument(
      id: const EntityId('doc-1'),
      userId: const EntityId('user-1'),
      petId: const EntityId('pet-1'),
      title: 'Passport',
      type: PetDocumentType.passport,
      fileUrl: Uri.parse('https://example.com/doc.pdf'),
      storagePath: 'users/user-1/pets/pet-1/documents/doc-1.pdf',
    );

Reminder _reminder() => Reminder(
      id: const EntityId('r-1'),
      userId: const EntityId('user-1'),
      petId: const EntityId('pet-1'),
      title: 'Check-up',
      dateTime: UtcDateTime(DateTime.utc(2026, 2, 1)),
    );

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
  _FakeTimelineRepository({this.events = const []});

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

class _FakeDocumentRepository implements DocumentRepository {
  _FakeDocumentRepository({this.documents = const []});

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
  _FakeReminderRepository({this.reminders = const []});

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
