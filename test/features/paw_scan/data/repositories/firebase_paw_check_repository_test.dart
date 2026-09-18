import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/paw_scan/data/datasources/firestore_paw_check_data_source.dart';
import 'package:paw_vault/features/paw_scan/data/repositories/firebase_paw_check_repository.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';

PawCheck _check({PawCheckStatus status = PawCheckStatus.confirmed}) {
  return PawCheck(
    id: const EntityId('check-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    location: PawLocation.frontLeft,
    attentionLevel: PawAttentionLevel.monitor,
    checkedAt: UtcDateTime(DateTime.utc(2026, 9, 18)),
    status: status,
  );
}

void main() {
  group('FirebasePawCheckRepository', () {
    test('unwraps ids when watching checks', () {
      final dataSource = _FakeFirestorePawCheckDataSource();
      final repository = FirebasePawCheckRepository(dataSource);

      repository.watchChecks(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
      );

      expect(dataSource.watchedUserId, 'user-1');
      expect(dataSource.watchedPetId, 'pet-1');
    });

    test('unwraps ids when getting a check', () async {
      final dataSource = _FakeFirestorePawCheckDataSource();
      final repository = FirebasePawCheckRepository(dataSource);

      await repository.getCheck(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        checkId: const EntityId('check-1'),
      );

      expect(dataSource.requestedCheckId, 'check-1');
    });

    test('unwraps ids when deleting a check', () async {
      final dataSource = _FakeFirestorePawCheckDataSource();
      final repository = FirebasePawCheckRepository(dataSource);

      await repository.deleteCheck(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        checkId: const EntityId('check-1'),
      );

      expect(dataSource.deletedCheckId, 'check-1');
    });

    test('forwards initialize', () async {
      final dataSource = _FakeFirestorePawCheckDataSource();
      final repository = FirebasePawCheckRepository(dataSource);

      await repository.initialize();

      expect(dataSource.initializeCallCount, 1);
    });

    test('saves a confirmed check', () async {
      final dataSource = _FakeFirestorePawCheckDataSource();
      final repository = FirebasePawCheckRepository(dataSource);

      await repository.saveCheck(_check());

      expect(dataSource.savedCheck?.id, const EntityId('check-1'));
    });

    test('refuses to save an unconfirmed check', () async {
      // The backstop for the whole feature: an AI draft can never reach the
      // archive without the owner having confirmed it.
      final dataSource = _FakeFirestorePawCheckDataSource();
      final repository = FirebasePawCheckRepository(dataSource);

      expect(
        () => repository.saveCheck(_check(status: PawCheckStatus.draft)),
        throwsStateError,
      );
      expect(dataSource.savedCheck, isNull);
    });

    test('a check built without an explicit status is not savable', () async {
      final dataSource = _FakeFirestorePawCheckDataSource();
      final repository = FirebasePawCheckRepository(dataSource);

      final unset = PawCheck(
        id: const EntityId('check-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        location: PawLocation.frontLeft,
        attentionLevel: PawAttentionLevel.monitor,
        checkedAt: UtcDateTime(DateTime.utc(2026, 9, 18)),
      );

      expect(() => repository.saveCheck(unset), throwsStateError);
      expect(dataSource.savedCheck, isNull);
    });
  });
}

class _FakeFirestorePawCheckDataSource implements FirestorePawCheckDataSource {
  int initializeCallCount = 0;
  String? watchedUserId;
  String? watchedPetId;
  String? requestedCheckId;
  String? deletedCheckId;
  PawCheck? savedCheck;

  @override
  Future<void> initialize() async {
    initializeCallCount++;
  }

  @override
  Stream<List<PawCheck>> watchChecks({
    required String userId,
    required String petId,
  }) {
    watchedUserId = userId;
    watchedPetId = petId;
    return Stream.value(const []);
  }

  @override
  Future<PawCheck?> getCheck({
    required String userId,
    required String petId,
    required String checkId,
  }) async {
    requestedCheckId = checkId;
    return null;
  }

  @override
  Future<void> saveCheck(PawCheck check) async {
    savedCheck = check;
  }

  @override
  Future<void> deleteCheck({
    required String userId,
    required String petId,
    required String checkId,
  }) async {
    deletedCheckId = checkId;
  }
}
