import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/dev/dev_seeder.dart';
import 'package:paw_vault/core/dev/sample_data.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';
import 'package:paw_vault/features/paw_scan/domain/repositories/paw_check_repository.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/entities/weight_entry.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/repositories/weight_entry_repository.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';

const _userId = EntityId('real-uid');

({
  DevSeeder seeder,
  _FakePetRepository pets,
  _FakeTimelineRepository timeline,
  _FakeDocumentRepository documents,
  _FakeReminderRepository reminders,
  _FakeSmartInputRepository smartInput,
  _FakePawCheckRepository pawChecks,
  _FakeWeightEntryRepository weights,
}) _build() {
  final pets = _FakePetRepository();
  final timeline = _FakeTimelineRepository();
  final documents = _FakeDocumentRepository();
  final reminders = _FakeReminderRepository();
  final smartInput = _FakeSmartInputRepository();
  final pawChecks = _FakePawCheckRepository();
  final weights = _FakeWeightEntryRepository();

  return (
    seeder: DevSeeder(
      petRepository: pets,
      timelineRepository: timeline,
      documentRepository: documents,
      reminderRepository: reminders,
      smartInputRepository: smartInput,
      pawCheckRepository: pawChecks,
      weightEntryRepository: weights,
    ),
    pets: pets,
    timeline: timeline,
    documents: documents,
    reminders: reminders,
    smartInput: smartInput,
    pawChecks: pawChecks,
    weights: weights,
  );
}

void main() {
  group('DevSeeder', () {
    test('writes records for every feature', () async {
      final t = _build();

      await t.seeder.seed(_userId);

      expect(t.pets.saved, isNotEmpty);
      expect(t.timeline.saved, isNotEmpty);
      expect(t.documents.saved, isNotEmpty);
      expect(t.reminders.saved, isNotEmpty);
      expect(t.pawChecks.saved, isNotEmpty);
      expect(t.weights.saved, isNotEmpty);
      expect(t.smartInput.saved, isNotEmpty);
    });

    test('keys every record to the signed-in account', () async {
      // The sample data is authored against a placeholder uid. If any record
      // kept it, that record would be written into a tree the signed-in user
      // cannot read, and the app would look half-empty.
      final t = _build();

      await t.seeder.seed(_userId);

      final userIds = <EntityId>{
        ...t.pets.saved.map((p) => p.userId),
        ...t.timeline.saved.map((e) => e.userId),
        ...t.documents.saved.map((d) => d.userId),
        ...t.reminders.saved.map((r) => r.userId),
        ...t.pawChecks.saved.map((c) => c.userId),
        ...t.weights.saved.map((w) => w.userId),
        ...t.smartInput.saved.map((m) => m.userId),
      };

      expect(userIds, {_userId});
      expect(userIds, isNot(contains(SampleData.userId)));
    });

    test('only seeds confirmed smart messages', () async {
      // The smart input repository rejects anything the user has not
      // confirmed, so seeding an unconfirmed sample would throw.
      final t = _build();

      await t.seeder.seed(_userId);

      expect(t.smartInput.saved, isNotEmpty);
      expect(
        t.smartInput.saved.map((m) => m.status),
        everyElement(SmartMessageStatus.confirmed),
      );
      expect(
        t.smartInput.saved.length,
        lessThan(SampleData.smartMessages.length),
        reason: 'the sample set contains an unconfirmed message to filter out',
      );
    });

    test('seeds paw checks as confirmed so they can be saved', () async {
      final t = _build();

      await t.seeder.seed(_userId);

      expect(
        t.pawChecks.saved.map((c) => c.status),
        everyElement(PawCheckStatus.confirmed),
      );
    });

    test('gives the journal two checks of the same paw to compare', () async {
      final t = _build();

      await t.seeder.seed(_userId);

      final frontLeft = t.pawChecks.saved
          .where((c) => c.location == SampleData.pawChecks.first.location);
      expect(frontLeft.length, greaterThanOrEqualTo(2));
    });

    group('seedIfEmpty', () {
      test('seeds an account with no pets', () async {
        final t = _build();

        final seeded = await t.seeder.seedIfEmpty(_userId);

        expect(seeded, isTrue);
        expect(t.pets.saved, isNotEmpty);
      });

      test('skips an account that already has pets', () async {
        // Launching repeatedly with the flag still set must not duplicate
        // everything, or overwrite data the tester entered by hand.
        final t = _build();
        t.pets.existing = [
          const Pet(
            id: EntityId('mine'),
            userId: _userId,
            name: 'Already here',
          ),
        ];

        final seeded = await t.seeder.seedIfEmpty(_userId);

        expect(seeded, isFalse);
        expect(t.pets.saved, isEmpty);
        expect(t.timeline.saved, isEmpty);
        expect(t.pawChecks.saved, isEmpty);
      });
    });
  });

  group('SampleData', () {
    test('builders key their records to the requested user', () {
      const other = EntityId('someone-else');

      expect(
        SampleData.petsFor(other).map((p) => p.userId),
        everyElement(other),
      );
      expect(
        SampleData.pawChecksFor(other).map((c) => c.userId),
        everyElement(other),
      );
    });

    test('the zero-argument getters still use the placeholder id', () {
      // The screenshot run depends on this.
      expect(
        SampleData.pets.map((p) => p.userId),
        everyElement(SampleData.userId),
      );
    });
  });
}

class _FakePetRepository implements PetRepository {
  List<Pet> existing = const [];
  final saved = <Pet>[];

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<Pet>> watchPets(EntityId userId) => Stream.value(existing);

  @override
  Future<Pet?> getPet({
    required EntityId userId,
    required EntityId petId,
  }) async =>
      null;

  @override
  Future<void> savePet(Pet pet) async => saved.add(pet);

  @override
  Future<void> deletePet({
    required EntityId userId,
    required EntityId petId,
  }) async {}
}

class _FakeTimelineRepository implements TimelineRepository {
  final saved = <PetEvent>[];

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PetEvent>> watchEvents({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream.value(const []);

  @override
  Future<PetEvent?> getEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async =>
      null;

  @override
  Future<void> saveEvent(PetEvent event) async => saved.add(event);

  @override
  Future<void> deleteEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async {}
}

class _FakeDocumentRepository implements DocumentRepository {
  final saved = <PetDocument>[];

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PetDocument>> watchDocuments({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream.value(const []);

  @override
  Future<PetDocument?> getDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async =>
      null;

  @override
  Future<void> saveDocument(PetDocument document) async => saved.add(document);

  @override
  Future<void> deleteDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async {}
}

class _FakeReminderRepository implements ReminderRepository {
  final saved = <Reminder>[];

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<Reminder>> watchReminders({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream.value(const []);

  @override
  Future<Reminder?> getReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async =>
      null;

  @override
  Future<void> saveReminder(Reminder reminder) async => saved.add(reminder);

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

class _FakeSmartInputRepository implements SmartInputRepository {
  final saved = <SmartMessage>[];

  @override
  Future<SmartInputDraft> createDraft(String input) async =>
      SmartInputDraft(originalText: input, requiresConfirmation: true);

  @override
  Stream<List<SmartMessage>> watchSmartMessages({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream.value(const []);

  @override
  Future<SmartMessage?> getSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) async =>
      null;

  @override
  Future<void> saveSmartMessage(SmartMessage message) async {
    // Mirrors the real repository's invariant, so the seeder cannot pass this
    // test while failing against Firebase.
    if (message.status != SmartMessageStatus.confirmed) {
      throw StateError('Smart messages must be confirmed before saving.');
    }
    saved.add(message);
  }

  @override
  Future<void> deleteSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) async {}
}

class _FakePawCheckRepository implements PawCheckRepository {
  final saved = <PawCheck>[];

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PawCheck>> watchChecks({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream.value(const []);

  @override
  Future<PawCheck?> getCheck({
    required EntityId userId,
    required EntityId petId,
    required EntityId checkId,
  }) async =>
      null;

  @override
  Future<void> saveCheck(PawCheck check) async {
    if (check.status != PawCheckStatus.confirmed) {
      throw StateError('Paw checks must be confirmed before saving.');
    }
    saved.add(check);
  }

  @override
  Future<void> deleteCheck({
    required EntityId userId,
    required EntityId petId,
    required EntityId checkId,
  }) async {}
}

class _FakeWeightEntryRepository implements WeightEntryRepository {
  final saved = <WeightEntry>[];

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<WeightEntry>> watchEntries({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream.value(const []);

  @override
  Future<void> saveEntry(WeightEntry entry) async => saved.add(entry);

  @override
  Future<void> deleteEntry({
    required EntityId userId,
    required EntityId petId,
    required EntityId entryId,
  }) async {}
}
