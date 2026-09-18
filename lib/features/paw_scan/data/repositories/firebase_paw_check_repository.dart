import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/paw_scan/data/datasources/firestore_paw_check_data_source.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';
import 'package:paw_vault/features/paw_scan/domain/repositories/paw_check_repository.dart';

class FirebasePawCheckRepository implements PawCheckRepository {
  const FirebasePawCheckRepository(this._dataSource);

  final FirestorePawCheckDataSource _dataSource;

  @override
  Future<void> initialize() => _dataSource.initialize();

  @override
  Stream<List<PawCheck>> watchChecks({
    required EntityId userId,
    required EntityId petId,
  }) {
    return _dataSource.watchChecks(
      userId: userId.value,
      petId: petId.value,
    );
  }

  @override
  Future<PawCheck?> getCheck({
    required EntityId userId,
    required EntityId petId,
    required EntityId checkId,
  }) {
    return _dataSource.getCheck(
      userId: userId.value,
      petId: petId.value,
      checkId: checkId.value,
    );
  }

  /// The backstop for the whole feature: an AI draft can only ever become a
  /// record by way of a confirmed [PawCheck], so nothing the model produced
  /// reaches the archive without the owner having said yes.
  @override
  Future<void> saveCheck(PawCheck check) {
    if (check.status != PawCheckStatus.confirmed) {
      throw StateError(
        'Paw checks must be confirmed by the user before saving.',
      );
    }

    return _dataSource.saveCheck(check);
  }

  @override
  Future<void> deleteCheck({
    required EntityId userId,
    required EntityId petId,
    required EntityId checkId,
  }) {
    return _dataSource.deleteCheck(
      userId: userId.value,
      petId: petId.value,
      checkId: checkId.value,
    );
  }
}
