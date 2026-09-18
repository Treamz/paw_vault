import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_paths.dart';

/// Per-pet builders that are deliberately **not** collections.
///
/// `pet` returns the pet document itself, so it has no place in the
/// subcollection set.
const _nonCollectionPetBuilders = {'pet'};

/// Finds every `static String name({required String userId, required String
/// petId})` builder declared in `firestore_paths.dart`.
///
/// Reading the source is unusual for a unit test, but it is what makes the
/// guarantee real: an in-code list can only assert what someone remembered to
/// add, whereas this fails the moment a new per-pet collection builder is
/// declared and not wired into [FirestorePaths.petSubcollections].
Set<String> _declaredPetCollectionBuilders() {
  final source = File(
    'lib/core/firebase/firestore/firestore_paths.dart',
  ).readAsStringSync();

  final builder = RegExp(
    r'static String (\w+)\(\{\s*required String userId,\s*'
    r'required String petId,\s*\}\)',
  );

  return builder
      .allMatches(source)
      .map((match) => match.group(1)!)
      .where((name) => !_nonCollectionPetBuilders.contains(name))
      .toSet();
}

void main() {
  group('FirestorePaths', () {
    test('nests every per-pet collection under the pet document', () {
      const userId = 'user-1';
      const petId = 'pet-1';
      final petPath = FirestorePaths.pet(userId: userId, petId: petId);

      expect(petPath, 'users/user-1/pets/pet-1');
      for (final path in FirestorePaths.petSubcollections(
        userId: userId,
        petId: petId,
      )) {
        expect(path, startsWith('$petPath/'));
      }
    });

    group('petSubcollections', () {
      test('includes weight entries', () {
        // The regression this test exists for: weight entries were missing
        // from account deletion's hand-written list, so a deleted account
        // left its weight history behind.
        expect(
          FirestorePaths.petSubcollections(userId: 'user-1', petId: 'pet-1'),
          contains('users/user-1/pets/pet-1/weightEntries'),
        );
      });

      test('lists every known per-pet collection', () {
        expect(
          FirestorePaths.petSubcollections(userId: 'user-1', petId: 'pet-1'),
          unorderedEquals([
            'users/user-1/pets/pet-1/events',
            'users/user-1/pets/pet-1/documents',
            'users/user-1/pets/pet-1/pawChecks',
            'users/user-1/pets/pet-1/reminders',
            'users/user-1/pets/pet-1/smartMessages',
            'users/user-1/pets/pet-1/vetSummaryExports',
            'users/user-1/pets/pet-1/weightEntries',
          ]),
        );
      });

      test('has no duplicates', () {
        final paths = FirestorePaths.petSubcollections(
          userId: 'user-1',
          petId: 'pet-1',
        );

        expect(paths.toSet(), hasLength(paths.length));
      });

      test('covers every per-pet collection builder declared in the file', () {
        // The anti-staleness guard. If you added a per-pet collection and this
        // failed, add it to FirestorePaths.petSubcollections — otherwise
        // deleting an account will silently leave that collection behind.
        //
        // This relies on the file's convention that a builder's name matches
        // its collection segment (`weightEntries` -> `.../weightEntries`).
        final declared = _declaredPetCollectionBuilders();
        final paths = FirestorePaths.petSubcollections(
          userId: 'user-1',
          petId: 'pet-1',
        );

        // Sanity-check the discovery itself, so a broken regex cannot make
        // this test vacuously pass.
        expect(
          declared,
          containsAll(<String>['events', 'weightEntries', 'pawChecks']),
          reason: 'the source scan should find the known builders',
        );

        for (final name in declared) {
          expect(
            paths,
            contains(endsWith('/$name')),
            reason: 'FirestorePaths.$name is declared but not included in '
                'petSubcollections',
          );
        }
        expect(paths, hasLength(declared.length));
      });
    });
  });
}
