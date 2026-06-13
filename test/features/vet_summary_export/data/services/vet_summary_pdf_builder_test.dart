import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
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

    test('embeds the Unicode font and renders non-Latin-1 text', () async {
      final builder = VetSummaryPdfBuilder(assetBundle: _DiskAssetBundle());
      const data = VetSummaryData(
        pet: Pet(
          id: EntityId('pet-1'),
          userId: EntityId('user-1'),
          name: 'Bella',
          // Characters outside Latin-1: em dash, smart quotes, ellipsis,
          // accents, and Cyrillic — these get dropped by Helvetica.
          notes: 'Café visit — "smart quotes" … Привет',
        ),
      );

      final bytes = await builder.build(data);

      expect(utf8.decode(bytes.sublist(0, 4)), '%PDF');
      // The Noto Sans font is embedded (its name appears in the font dict).
      expect(latin1.decode(bytes, allowInvalid: true).contains('Noto'), isTrue);
    });
  });
}

/// Loads assets straight from disk so the builder's font path is exercised in
/// a plain unit test (no Flutter asset bundle required).
class _DiskAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
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
