import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/vet_summary_export/data/services/vet_summary_pdf_builder.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_data.dart';

void main() {
  group('VetSummaryPdfBuilder', () {
    test('produces a non-empty PDF document', () async {
      const builder = VetSummaryPdfBuilder();
      final data = VetSummaryData(
        pet: _pet(),
        events: [_event()],
      );

      final bytes = await builder.build(data);

      expect(bytes, isNotEmpty);
      // PDF files start with the "%PDF" magic header.
      expect(utf8.decode(bytes.sublist(0, 4)), '%PDF');
    });

    test('produces a valid PDF even with no records', () async {
      const builder = VetSummaryPdfBuilder();
      final bytes = await builder.build(VetSummaryData(pet: _pet()));

      expect(bytes, isNotEmpty);
      expect(utf8.decode(bytes.sublist(0, 4)), '%PDF');
    });

    test('renders a full record set (overview, docs, reminders) without error',
        () async {
      const builder = VetSummaryPdfBuilder();
      final data = VetSummaryData(
        pet: _pet(),
        events: [
          _event(),
          _event(
            id: 'event-2',
            type: PetEventType.symptom,
            title: 'Itchy paws',
            description: 'Licking and chewing at the left front paw after '
                'meals; mild redness observed over three days.',
          ),
          _event(
            id: 'event-3',
            type: PetEventType.medication,
            title: 'Apoquel 16mg',
          ),
          _event(
            id: 'event-4',
            type: PetEventType.allergy,
            title: 'Chicken',
          ),
        ],
        documents: [_document()],
        reminders: [_reminder()],
      );

      final bytes = await builder.build(data);

      expect(bytes, isNotEmpty);
      expect(utf8.decode(bytes.sublist(0, 4)), '%PDF');
    });
  });
}

Pet _pet() => const Pet(
      id: EntityId('pet-1'),
      userId: EntityId('user-1'),
      name: 'Bella',
      species: 'Dog',
      breed: 'Corgi',
      birthDate: DateOnly(year: 2021, month: 3, day: 14),
      allergies: ['Pollen'],
      chronicConditions: ['Hip dysplasia'],
      notes: 'Friendly, anxious at the clinic.',
    );

PetEvent _event({
  String id = 'event-1',
  PetEventType type = PetEventType.vaccination,
  String title = 'Rabies',
  String? description,
}) =>
    PetEvent(
      id: EntityId(id),
      userId: const EntityId('user-1'),
      petId: const EntityId('pet-1'),
      type: type,
      title: title,
      date: UtcDateTime(DateTime.utc(2026)),
      source: PetEventSource.manual,
      description: description,
    );

PetDocument _document() => PetDocument(
      id: const EntityId('doc-1'),
      userId: const EntityId('user-1'),
      petId: const EntityId('pet-1'),
      title: 'Blood panel results',
      type: PetDocumentType.labResult,
      fileUrl: Uri.parse('https://example.com/labs.pdf'),
      storagePath: 'users/user-1/pets/pet-1/documents/doc-1.pdf',
      issueDate: const DateOnly(year: 2026, month: 2, day: 22),
      notes: 'Reviewed with Dr. Lee.',
      extractedText: 'Complete blood count within normal limits. Mild '
          'elevation in ALT noted; recommend recheck in three months. '
          'No abnormalities in kidney values.',
    );

Reminder _reminder() => Reminder(
      id: const EntityId('rem-1'),
      userId: const EntityId('user-1'),
      petId: const EntityId('pet-1'),
      title: 'Rabies booster due',
      dateTime: UtcDateTime(DateTime.utc(2027, 5, 2, 9)),
      repeatType: ReminderRepeatType.yearly,
    );
