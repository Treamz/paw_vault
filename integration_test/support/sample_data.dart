// Seed data for App Store screenshots — realistic, friendly content that shows
// off each feature. Not used by the shipping app.
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_export.dart';

abstract final class SampleData {
  static const userId = EntityId('user-1');
  static const petId = EntityId('pet-1');

  static UtcDateTime _at(int y, int m, int d) =>
      UtcDateTime(DateTime.utc(y, m, d, 9));

  static const List<Pet> pets = <Pet>[
    Pet(
      id: EntityId('pet-1'),
      userId: userId,
      name: 'Bella',
      species: 'Dog',
      breed: 'Golden Retriever',
      birthDate: DateOnly(year: 2021, month: 3, day: 14),
      gender: PetGender.female,
      weight: PetWeight(value: 28.5),
      microchipNumber: '985112000123456',
      allergies: <String>['Chicken'],
      chronicConditions: <String>['Hip dysplasia'],
      notes: 'Loves the lake. Friendly with kids and other dogs.',
    ),
    Pet(
      id: EntityId('pet-2'),
      userId: userId,
      name: 'Max',
      species: 'Cat',
      breed: 'Maine Coon',
      birthDate: DateOnly(year: 2020, month: 9, day: 2),
      gender: PetGender.male,
      weight: PetWeight(value: 6.2),
    ),
    Pet(
      id: EntityId('pet-3'),
      userId: userId,
      name: 'Luna',
      species: 'Dog',
      breed: 'Border Collie',
      birthDate: DateOnly(year: 2022, month: 6, day: 21),
      gender: PetGender.female,
      weight: PetWeight(value: 18.0),
    ),
  ];

  static final List<PetEvent> events = <PetEvent>[
    PetEvent(
      id: const EntityId('event-1'),
      userId: userId,
      petId: petId,
      type: PetEventType.vaccination,
      title: 'Rabies booster',
      date: _at(2026, 5, 2),
      source: PetEventSource.manual,
      description: 'Administered by Dr. Lee at Lakeside Vet Clinic.',
    ),
    PetEvent(
      id: const EntityId('event-2'),
      userId: userId,
      petId: petId,
      type: PetEventType.vetVisit,
      title: 'Annual wellness exam',
      date: _at(2026, 4, 18),
      source: PetEventSource.manual,
      description: 'Healthy weight, clean teeth, all clear.',
    ),
    PetEvent(
      id: const EntityId('event-3'),
      userId: userId,
      petId: petId,
      type: PetEventType.medication,
      title: 'Apoquel 16mg — once daily',
      date: _at(2026, 3, 10),
      source: PetEventSource.smartText,
    ),
    PetEvent(
      id: const EntityId('event-4'),
      userId: userId,
      petId: petId,
      type: PetEventType.labTest,
      title: 'Full blood panel',
      date: _at(2026, 2, 22),
      source: PetEventSource.documentScan,
    ),
    PetEvent(
      id: const EntityId('event-5'),
      userId: userId,
      petId: petId,
      type: PetEventType.grooming,
      title: 'Full groom & nail trim',
      date: _at(2026, 1, 15),
      source: PetEventSource.manual,
    ),
  ];

  static final List<PetDocument> documents = <PetDocument>[
    PetDocument(
      id: const EntityId('doc-1'),
      userId: userId,
      petId: petId,
      title: 'Rabies vaccination certificate',
      type: PetDocumentType.vaccinationCertificate,
      fileUrl: Uri.parse('https://example.com/rabies.pdf'),
      storagePath: 'users/user-1/pets/pet-1/documents/doc-1.pdf',
      issueDate: const DateOnly(year: 2026, month: 5, day: 2),
      expiryDate: const DateOnly(year: 2029, month: 5, day: 2),
    ),
    PetDocument(
      id: const EntityId('doc-2'),
      userId: userId,
      petId: petId,
      title: 'Pet insurance policy',
      type: PetDocumentType.insurance,
      fileUrl: Uri.parse('https://example.com/insurance.pdf'),
      storagePath: 'users/user-1/pets/pet-1/documents/doc-2.pdf',
      issueDate: const DateOnly(year: 2026, month: 1, day: 1),
      expiryDate: const DateOnly(year: 2027, month: 1, day: 1),
    ),
    PetDocument(
      id: const EntityId('doc-3'),
      userId: userId,
      petId: petId,
      title: 'Blood panel results',
      type: PetDocumentType.labResult,
      fileUrl: Uri.parse('https://example.com/labs.pdf'),
      storagePath: 'users/user-1/pets/pet-1/documents/doc-3.pdf',
      issueDate: const DateOnly(year: 2026, month: 2, day: 22),
    ),
  ];

  static final List<Reminder> reminders = <Reminder>[
    Reminder(
      id: const EntityId('rem-1'),
      userId: userId,
      petId: petId,
      title: 'Rabies booster due',
      dateTime: _at(2027, 5, 2),
      description: 'Yearly booster at Lakeside Vet Clinic.',
      repeatType: ReminderRepeatType.yearly,
    ),
    Reminder(
      id: const EntityId('rem-2'),
      userId: userId,
      petId: petId,
      title: 'Flea & tick treatment',
      dateTime: _at(2026, 7, 1),
      repeatType: ReminderRepeatType.monthly,
    ),
    Reminder(
      id: const EntityId('rem-3'),
      userId: userId,
      petId: petId,
      title: 'Annual wellness exam',
      dateTime: _at(2027, 4, 18),
      repeatType: ReminderRepeatType.yearly,
    ),
  ];

  static const List<SmartMessage> smartMessages = <SmartMessage>[
    SmartMessage(
      id: EntityId('sm-1'),
      userId: userId,
      petId: petId,
      originalText: 'Bella got her rabies shot today at Dr. Lee.',
      detectedIntent: SmartMessageIntent.addVaccination,
      confidence: 0.96,
      status: SmartMessageStatus.confirmed,
    ),
    SmartMessage(
      id: EntityId('sm-2'),
      userId: userId,
      petId: petId,
      originalText: 'Started Bella on Apoquel 16mg once daily.',
      detectedIntent: SmartMessageIntent.addMedication,
      confidence: 0.92,
      status: SmartMessageStatus.confirmed,
    ),
    SmartMessage(
      id: EntityId('sm-3'),
      userId: userId,
      petId: petId,
      originalText: 'She seemed itchy after eating chicken.',
      detectedIntent: SmartMessageIntent.addAllergy,
      confidence: 0.81,
      status: SmartMessageStatus.awaitingConfirmation,
    ),
  ];

  static final List<VetSummaryExport> exports = <VetSummaryExport>[
    VetSummaryExport(
      id: const EntityId('exp-1'),
      userId: userId,
      petId: petId,
      createdAt: _at(2026, 5, 10),
      fileUrl: Uri.parse('https://example.com/summary-may.pdf'),
      storagePath: 'users/user-1/pets/pet-1/exports/exp-1.pdf',
    ),
    VetSummaryExport(
      id: const EntityId('exp-2'),
      userId: userId,
      petId: petId,
      createdAt: _at(2026, 3, 1),
      fileUrl: Uri.parse('https://example.com/summary-mar.pdf'),
      storagePath: 'users/user-1/pets/pet-1/exports/exp-2.pdf',
    ),
  ];
}
