import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';

/// Firestore-facing contract for paw checks, in plain [String] ids.
///
/// This is the seam the repository tests fake, so no test needs Firestore.
abstract interface class FirestorePawCheckDataSource {
  Future<void> initialize();

  Stream<List<PawCheck>> watchChecks({
    required String userId,
    required String petId,
  });

  Future<PawCheck?> getCheck({
    required String userId,
    required String petId,
    required String checkId,
  });

  Future<void> saveCheck(PawCheck check);

  Future<void> deleteCheck({
    required String userId,
    required String petId,
    required String checkId,
  });
}
