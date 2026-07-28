import 'dart:async';

import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/domain/entities/weight_entry.dart';
import 'package:paw_vault/features/pets/domain/repositories/weight_entry_repository.dart';

/// In-memory [WeightEntryRepository] for local-first mode.
class LocalWeightEntryRepository implements WeightEntryRepository {
  final _entries = <WeightEntry>[];
  final _controller = StreamController<List<WeightEntry>>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<WeightEntry>> watchEntries({
    required EntityId userId,
    required EntityId petId,
  }) async* {
    List<WeightEntry> forPet(List<WeightEntry> entries) => [
          for (final e in entries)
            if (e.petId == petId) e,
        ];
    yield forPet(_entries);
    yield* _controller.stream.map(forPet);
  }

  @override
  Future<void> saveEntry(WeightEntry entry) async {
    _entries.removeWhere((existing) => existing.id == entry.id);
    _entries.add(entry);
    _controller.add(List.of(_entries));
  }

  @override
  Future<void> deleteEntry({
    required EntityId userId,
    required EntityId petId,
    required EntityId entryId,
  }) async {
    _entries.removeWhere((existing) => existing.id == entryId);
    _controller.add(List.of(_entries));
  }
}
