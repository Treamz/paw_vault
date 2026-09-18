import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';
import 'package:paw_vault/features/paw_scan/domain/repositories/paw_check_repository.dart';

/// Local-first stand-in: the journal is always empty and nothing is stored.
class LocalPawCheckRepository implements PawCheckRepository {
  const LocalPawCheckRepository();

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PawCheck>> watchChecks({
    required EntityId userId,
    required EntityId petId,
  }) {
    return Stream.value(const []);
  }

  @override
  Future<PawCheck?> getCheck({
    required EntityId userId,
    required EntityId petId,
    required EntityId checkId,
  }) async {
    return null;
  }

  @override
  Future<void> saveCheck(PawCheck check) async {}

  @override
  Future<void> deleteCheck({
    required EntityId userId,
    required EntityId petId,
    required EntityId checkId,
  }) async {}
}
