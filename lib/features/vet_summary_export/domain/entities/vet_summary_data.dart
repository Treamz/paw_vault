import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';

/// Aggregated, read-only snapshot of a pet's records used to build a vet
/// summary export.
class VetSummaryData {
  const VetSummaryData({
    required this.pet,
    this.events = const [],
    this.documents = const [],
    this.reminders = const [],
  });

  final Pet pet;
  final List<PetEvent> events;
  final List<PetDocument> documents;
  final List<Reminder> reminders;

  bool get hasRecords =>
      events.isNotEmpty || documents.isNotEmpty || reminders.isNotEmpty;
}
