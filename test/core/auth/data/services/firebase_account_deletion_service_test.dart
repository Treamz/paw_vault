import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/data/services/firebase_account_deletion_service.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_paths.dart';

void main() {
  group('FirebaseAccountDeletionService', () {
    // The service takes FirebaseFirestore/Auth/Storage directly, and the repo
    // has no Firestore fake, so the traversal itself is not unit-testable.
    // What is testable — and what the data-retention bug actually was — is the
    // set of collections the service plans to delete.
    group('petSubcollectionPaths', () {
      test('deletes weight entries', () {
        // The regression: weight entries were absent from a hand-written
        // list, so a user who asked for their account to be deleted kept a
        // full weight history in Firestore.
        expect(
          FirebaseAccountDeletionService.petSubcollectionPaths(
            uid: 'user-1',
            petId: 'pet-1',
          ),
          contains('users/user-1/pets/pet-1/weightEntries'),
        );
      });

      test('deletes every per-pet collection PawVault writes', () {
        // Derived, not duplicated: if this ever diverges from
        // FirestorePaths.petSubcollections, the service has grown its own list
        // again and the bug can come back.
        expect(
          FirebaseAccountDeletionService.petSubcollectionPaths(
            uid: 'user-1',
            petId: 'pet-1',
          ),
          FirestorePaths.petSubcollections(userId: 'user-1', petId: 'pet-1'),
        );
      });

      test('scopes every path to the account being deleted', () {
        // A path that escaped the user's own tree would either fail security
        // rules or, worse, touch another account's data.
        final paths = FirebaseAccountDeletionService.petSubcollectionPaths(
          uid: 'user-1',
          petId: 'pet-1',
        );

        expect(paths, isNotEmpty);
        for (final path in paths) {
          expect(path, startsWith('users/user-1/pets/pet-1/'));
        }
      });
    });
  });
}
