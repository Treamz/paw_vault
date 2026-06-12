import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_data.dart';

void main() {
  group('VetSummaryData', () {
    test('defaults record lists to empty and reports no records', () {
      final data = VetSummaryData(pet: _pet());

      expect(data.events, isEmpty);
      expect(data.documents, isEmpty);
      expect(data.reminders, isEmpty);
      expect(data.hasRecords, isFalse);
    });

    test('hasRecords is true when any record list is non-empty', () {
      final withEvent = VetSummaryData(pet: _pet(), events: [_event()]);
      final withReminder =
          VetSummaryData(pet: _pet(), reminders: [_reminder()]);

      expect(withEvent.hasRecords, isTrue);
      expect(withReminder.hasRecords, isTrue);
    });
  });
}

Pet _pet() {
  return const Pet(
    id: EntityId('pet-1'),
    userId: EntityId('user-1'),
    name: 'Bella',
  );
}

PetEvent _event() {
  return PetEvent(
    id: const EntityId('event-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    type: PetEventType.vaccination,
    title: 'Rabies',
    date: UtcDateTime(DateTime.utc(2026, 1, 1)),
    source: PetEventSource.manual,
  );
}

Reminder _reminder() {
  return Reminder(
    id: const EntityId('r-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    title: 'Check-up',
    dateTime: UtcDateTime(DateTime.utc(2026, 2, 1)),
  );
}
