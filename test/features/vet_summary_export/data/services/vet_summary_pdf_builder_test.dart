import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
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
  });
}

Pet _pet() => const Pet(
      id: EntityId('pet-1'),
      userId: EntityId('user-1'),
      name: 'Bella',
      species: 'Dog',
      breed: 'Corgi',
      allergies: ['Pollen'],
    );

PetEvent _event() => PetEvent(
      id: const EntityId('event-1'),
      userId: const EntityId('user-1'),
      petId: const EntityId('pet-1'),
      type: PetEventType.vaccination,
      title: 'Rabies',
      date: UtcDateTime(DateTime.utc(2026)),
      source: PetEventSource.manual,
    );
