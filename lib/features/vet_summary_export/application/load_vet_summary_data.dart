import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/paw_scan/domain/repositories/paw_check_repository.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_data.dart';

/// Loads a snapshot of a pet's records (profile, events, documents, reminders)
/// and composes it into [VetSummaryData] for export.
class LoadVetSummaryData {
  LoadVetSummaryData({
    required PetRepository petRepository,
    required TimelineRepository timelineRepository,
    required DocumentRepository documentRepository,
    required ReminderRepository reminderRepository,
    required PawCheckRepository pawCheckRepository,
  })  : _petRepository = petRepository,
        _timelineRepository = timelineRepository,
        _documentRepository = documentRepository,
        _reminderRepository = reminderRepository,
        _pawCheckRepository = pawCheckRepository;

  final PetRepository _petRepository;
  final TimelineRepository _timelineRepository;
  final DocumentRepository _documentRepository;
  final ReminderRepository _reminderRepository;
  final PawCheckRepository _pawCheckRepository;

  Future<VetSummaryData> call({
    required EntityId userId,
    required EntityId petId,
  }) async {
    await _petRepository.initialize();
    await _timelineRepository.initialize();
    await _documentRepository.initialize();
    await _reminderRepository.initialize();
    await _pawCheckRepository.initialize();

    final pet = await _petRepository.getPet(userId: userId, petId: petId);
    if (pet == null) {
      throw StateError('Pet not found');
    }

    final events = await _timelineRepository
        .watchEvents(userId: userId, petId: petId)
        .first;
    final documents = await _documentRepository
        .watchDocuments(userId: userId, petId: petId)
        .first;
    final reminders = await _reminderRepository
        .watchReminders(userId: userId, petId: petId)
        .first;

    // Paw checks are opt-in: filtering here keeps the PDF builder unaware of
    // the distinction, and means an owner's private checks never leave the
    // app by accident.
    final pawChecks = (await _pawCheckRepository
            .watchChecks(userId: userId, petId: petId)
            .first)
        .where((check) => check.includeInVetSummary)
        .toList();

    return VetSummaryData(
      pet: pet,
      events: events,
      documents: documents,
      reminders: reminders,
      pawChecks: pawChecks,
    );
  }
}
