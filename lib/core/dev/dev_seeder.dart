import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:paw_vault/core/dev/sample_data.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/paw_scan/domain/repositories/paw_check_repository.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/repositories/weight_entry_repository.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';

/// Fills a signed-in account with [SampleData] so a test account has something
/// to look at.
///
/// Debug-only, twice over: the dart-define has to be passed **and** the build
/// has to be a debug build, so a release build can never seed even if the flag
/// is left in a CI command by accident.
///
/// Writes go through the feature repositories, never Firebase directly, so the
/// same seeder works against whatever `AppDependencies` was composed with.
class DevSeeder {
  const DevSeeder({
    required PetRepository petRepository,
    required TimelineRepository timelineRepository,
    required DocumentRepository documentRepository,
    required ReminderRepository reminderRepository,
    required SmartInputRepository smartInputRepository,
    required PawCheckRepository pawCheckRepository,
    required WeightEntryRepository weightEntryRepository,
  })  : _petRepository = petRepository,
        _timelineRepository = timelineRepository,
        _documentRepository = documentRepository,
        _reminderRepository = reminderRepository,
        _smartInputRepository = smartInputRepository,
        _pawCheckRepository = pawCheckRepository,
        _weightEntryRepository = weightEntryRepository;

  final PetRepository _petRepository;
  final TimelineRepository _timelineRepository;
  final DocumentRepository _documentRepository;
  final ReminderRepository _reminderRepository;
  final SmartInputRepository _smartInputRepository;
  final PawCheckRepository _pawCheckRepository;
  final WeightEntryRepository _weightEntryRepository;

  /// Set with `--dart-define=PAWVAULT_SEED=true`.
  static const seedRequested = bool.fromEnvironment('PAWVAULT_SEED');

  /// Whether seeding may run at all in this build.
  static bool get isEnabled => kDebugMode && seedRequested;

  /// Seeds [userId] unless it already has pets.
  ///
  /// Skipping when data exists keeps the app launchable repeatedly with the
  /// flag still set, and stops a second run from duplicating everything.
  /// Returns whether anything was written.
  Future<bool> seedIfEmpty(EntityId userId) async {
    await _petRepository.initialize();

    final existing = await _petRepository.watchPets(userId).first;
    if (existing.isNotEmpty) {
      return false;
    }

    await seed(userId);
    return true;
  }

  /// Writes every sample record, keyed to [userId].
  ///
  /// Pet and record ids come from the sample data unchanged: they are document
  /// ids inside this user's own subtree, so they cannot collide with another
  /// account.
  Future<void> seed(EntityId userId) async {
    await _timelineRepository.initialize();
    await _documentRepository.initialize();
    await _reminderRepository.initialize();
    await _pawCheckRepository.initialize();
    await _weightEntryRepository.initialize();

    for (final pet in SampleData.petsFor(userId)) {
      await _petRepository.savePet(pet);
    }
    for (final event in SampleData.eventsFor(userId)) {
      await _timelineRepository.saveEvent(event);
    }
    for (final document in SampleData.documentsFor(userId)) {
      await _documentRepository.saveDocument(document);
    }
    for (final reminder in SampleData.remindersFor(userId)) {
      await _reminderRepository.saveReminder(reminder);
    }
    for (final check in SampleData.pawChecksFor(userId)) {
      await _pawCheckRepository.saveCheck(check);
    }
    for (final entry in SampleData.weightEntriesFor(userId)) {
      await _weightEntryRepository.saveEntry(entry);
    }

    // Only confirmed messages may be saved — the smart input repository
    // rejects anything the user has not approved, so an unconfirmed sample
    // would throw rather than seed.
    final confirmed = SampleData.smartMessagesFor(userId)
        .where((message) => message.status == SmartMessageStatus.confirmed);
    for (final message in confirmed) {
      await _smartInputRepository.saveSmartMessage(message);
    }
  }
}
