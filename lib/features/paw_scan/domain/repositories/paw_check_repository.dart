import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';

abstract interface class PawCheckRepository {
  Future<void> initialize();

  Stream<List<PawCheck>> watchChecks({
    required EntityId userId,
    required EntityId petId,
  });

  Future<PawCheck?> getCheck({
    required EntityId userId,
    required EntityId petId,
    required EntityId checkId,
  });

  /// Saves a confirmed check.
  ///
  /// Implementations must reject anything the owner has not confirmed, so an
  /// AI draft can never reach the archive on its own.
  Future<void> saveCheck(PawCheck check);

  Future<void> deleteCheck({
    required EntityId userId,
    required EntityId petId,
    required EntityId checkId,
  });
}
