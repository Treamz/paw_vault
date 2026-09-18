// Realistic sample content that shows off every feature.
//
// Used by the App Store screenshot run and by [DevSeeder], which writes it
// into a real account in debug builds. Nothing in the shipping app reads it:
// the only caller is gated behind `kDebugMode` and a dart-define.
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/entities/weight_entry.dart';
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

  static List<Pet> petsFor(EntityId userId) => <Pet>[
        Pet(
          id: const EntityId('pet-1'),
          userId: userId,
          name: 'Bella',
          species: 'Dog',
          breed: 'Golden Retriever',
          birthDate: const DateOnly(year: 2021, month: 3, day: 14),
          gender: PetGender.female,
          weight: const PetWeight(value: 28.5),
          microchipNumber: '985112000123456',
          allergies: <String>['Chicken'],
          chronicConditions: <String>['Hip dysplasia'],
          notes: 'Loves the lake. Friendly with kids and other dogs.',
        ),
        Pet(
          id: const EntityId('pet-2'),
          userId: userId,
          name: 'Max',
          species: 'Cat',
          breed: 'Maine Coon',
          birthDate: const DateOnly(year: 2020, month: 9, day: 2),
          gender: PetGender.male,
          weight: const PetWeight(value: 6.2),
        ),
        Pet(
          id: const EntityId('pet-3'),
          userId: userId,
          name: 'Luna',
          species: 'Dog',
          breed: 'Border Collie',
          birthDate: const DateOnly(year: 2022, month: 6, day: 21),
          gender: PetGender.female,
          weight: const PetWeight(value: 18.0),
        ),
      ];

  static List<PetEvent> eventsFor(EntityId userId) => <PetEvent>[
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

  static List<PetDocument> documentsFor(EntityId userId) => <PetDocument>[
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

  static List<Reminder> remindersFor(EntityId userId) => <Reminder>[
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

  static List<SmartMessage> smartMessagesFor(EntityId userId) => <SmartMessage>[
        SmartMessage(
          id: const EntityId('sm-1'),
          userId: userId,
          petId: petId,
          originalText: 'Bella got her rabies shot today at Dr. Lee.',
          detectedIntent: SmartMessageIntent.addVaccination,
          confidence: 0.96,
          status: SmartMessageStatus.confirmed,
        ),
        SmartMessage(
          id: const EntityId('sm-2'),
          userId: userId,
          petId: petId,
          originalText: 'Started Bella on Apoquel 16mg once daily.',
          detectedIntent: SmartMessageIntent.addMedication,
          confidence: 0.92,
          status: SmartMessageStatus.confirmed,
        ),
        SmartMessage(
          id: const EntityId('sm-3'),
          userId: userId,
          petId: petId,
          originalText: 'She seemed itchy after eating chicken.',
          detectedIntent: SmartMessageIntent.addAllergy,
          confidence: 0.81,
          status: SmartMessageStatus.awaitingConfirmation,
        ),
      ];

  static List<VetSummaryExport> exportsFor(EntityId userId) =>
      <VetSummaryExport>[
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

  /// Two checks of the same paw, twelve days apart, so the journal's
  /// before/after comparison has something to compare.
  static List<PawCheck> pawChecksFor(EntityId userId) => <PawCheck>[
        PawCheck(
          id: const EntityId('paw-1'),
          userId: userId,
          petId: petId,
          location: PawLocation.frontLeft,
          attentionLevel: PawAttentionLevel.monitor,
          checkedAt: _at(2026, 5, 6),
          observations: const [
            'A darker area near the centre of the main pad.',
            'The fur between the two middle toes looks slightly matted.',
          ],
          summary: 'One pad looks different from the others.',
          ownerNote: 'She was licking it after our walk.',
          confidence: 0.82,
          status: PawCheckStatus.confirmed,
        ),
        PawCheck(
          id: const EntityId('paw-2'),
          userId: userId,
          petId: petId,
          location: PawLocation.frontLeft,
          attentionLevel: PawAttentionLevel.vetSoon,
          checkedAt: _at(2026, 5, 18),
          observations: const [
            'The darker area on the main pad looks larger than before.',
          ],
          summary: 'The area on the main pad has changed since the last check.',
          includeInVetSummary: true,
          confidence: 0.88,
          status: PawCheckStatus.confirmed,
        ),
      ];

  /// A gentle upward trend, so the weight chart has a shape.
  static List<WeightEntry> weightEntriesFor(EntityId userId) => <WeightEntry>[
        WeightEntry(
          id: const EntityId('w-1'),
          userId: userId,
          petId: petId,
          value: 26.8,
          date: const DateOnly(year: 2026, month: 1, day: 12),
        ),
        WeightEntry(
          id: const EntityId('w-2'),
          userId: userId,
          petId: petId,
          value: 27.4,
          date: const DateOnly(year: 2026, month: 3, day: 2),
        ),
        WeightEntry(
          id: const EntityId('w-3'),
          userId: userId,
          petId: petId,
          value: 28.1,
          date: const DateOnly(year: 2026, month: 4, day: 20),
          note: 'After switching food.',
        ),
        WeightEntry(
          id: const EntityId('w-4'),
          userId: userId,
          petId: petId,
          value: 28.5,
          date: const DateOnly(year: 2026, month: 5, day: 18),
        ),
      ];

  /// Keyed to the placeholder [userId]; used by the screenshot run.
  static List<Pet> get pets => petsFor(userId);

  /// Keyed to the placeholder [userId]; used by the screenshot run.
  static List<PetEvent> get events => eventsFor(userId);

  /// Keyed to the placeholder [userId]; used by the screenshot run.
  static List<PetDocument> get documents => documentsFor(userId);

  /// Keyed to the placeholder [userId]; used by the screenshot run.
  static List<Reminder> get reminders => remindersFor(userId);

  /// Keyed to the placeholder [userId]; used by the screenshot run.
  static List<SmartMessage> get smartMessages => smartMessagesFor(userId);

  /// Keyed to the placeholder [userId]; used by the screenshot run.
  static List<VetSummaryExport> get exports => exportsFor(userId);

  /// Keyed to the placeholder [userId]; used by the screenshot run.
  static List<PawCheck> get pawChecks => pawChecksFor(userId);

  /// Keyed to the placeholder [userId]; used by the screenshot run.
  static List<WeightEntry> get weightEntries => weightEntriesFor(userId);
}
