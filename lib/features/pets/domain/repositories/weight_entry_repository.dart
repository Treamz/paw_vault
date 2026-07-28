import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/domain/entities/weight_entry.dart';

/// Stores a pet's weight history, one entry per measurement.
abstract interface class WeightEntryRepository {
  Future<void> initialize();

  /// All entries for the pet; ordering is up to the consumer.
  Stream<List<WeightEntry>> watchEntries({
    required EntityId userId,
    required EntityId petId,
  });

  Future<void> saveEntry(WeightEntry entry);

  Future<void> deleteEntry({
    required EntityId userId,
    required EntityId petId,
    required EntityId entryId,
  });
}
