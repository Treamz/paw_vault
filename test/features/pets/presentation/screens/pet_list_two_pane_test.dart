import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/data/services/noop_account_deletion_service.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/account_auth_repository.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/auth/domain/services/account_deletion_service.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/core/subscription/presentation/cubit/subscription_cubit.dart';
import 'package:paw_vault/features/account/domain/repositories/owner_profile_repository.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/repositories/weight_entry_repository.dart';
import 'package:paw_vault/features/pets/presentation/screens/pet_list_screen.dart';
import 'package:paw_vault/features/pets/presentation/screens/pet_profile_screen.dart';

/// The pet list beside the selected pet, which the app shows on a surface
/// big enough for both. See `hasRoomForTwoPanes`.
void main() {
  const duoUnfolded = Size(951, 669);
  const phone = Size(440, 956);

  Future<void> pumpAt(WidgetTester tester, Size surface) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _TestApp());
    await tester.pumpAndSettle();
  }

  /// The chevron on one pet's row, which says the row leaves this screen.
  Finder rowChevron(String petId) => find.descendant(
        of: find.byKey(ValueKey('pet-$petId')),
        matching: find.byIcon(Icons.chevron_right),
      );

  /// A finder scoped to the detail pane, so a pet's name there is not
  /// confused with the same name in the list beside it.
  Finder inProfile(String text) => find.descendant(
        of: find.byType(PetProfileScreen),
        matching: find.text(text),
      );

  group('PetListScreen on a wide surface', () {
    testWidgets('shows the list and a pet beside it', (tester) async {
      await pumpAt(tester, duoUnfolded);

      expect(find.byType(PetProfileScreen), findsOneWidget);
      expect(find.text('Bella'), findsWidgets);
      expect(find.text('Max'), findsWidgets);
    });

    testWidgets('opens the first pet rather than leaving the pane blank',
        (tester) async {
      await pumpAt(tester, duoUnfolded);

      expect(inProfile('Bella'), findsOneWidget);
    });

    testWidgets('swaps the pane without leaving the list', (tester) async {
      await pumpAt(tester, duoUnfolded);

      await tester.tap(find.byKey(const ValueKey('pet-pet-2')));
      await tester.pumpAndSettle();

      expect(inProfile('Max'), findsOneWidget);
      // The whole point: picking a pet is a choice made here, not a way out
      // of this screen, so the list must still be beside it.
      expect(find.byKey(const ValueKey('pet-pet-1')), findsOneWidget);
    });

    testWidgets('drops the chevron, which would promise a push',
        (tester) async {
      await pumpAt(tester, duoUnfolded);

      // Scoped to a row: the profile beside it has chevrons of its own, on
      // the sections that really do open as their own screen.
      expect(rowChevron('pet-1'), findsNothing);
    });
  });

  group('PetListScreen on a phone', () {
    testWidgets('keeps one pane and the chevron', (tester) async {
      await pumpAt(tester, phone);

      expect(find.byType(PetProfileScreen), findsNothing);
      expect(rowChevron('pet-1'), findsOneWidget);
      expect(rowChevron('pet-2'), findsOneWidget);
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context) {
    // The profile pane reads several repositories this test has no opinion
    // about; local-first already carries working ones.
    final base = AppDependencies.localFirst();

    const auth = _FakeAuthRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: auth),
        RepositoryProvider<AccountAuthRepository>.value(value: auth),
        RepositoryProvider<AccountDeletionService>.value(
          value: const NoopAccountDeletionService(),
        ),
        RepositoryProvider<PetRepository>.value(value: _FakePetRepository()),
        RepositoryProvider<StorageRepository>.value(
          value: base.storageRepository,
        ),
        RepositoryProvider<OwnerProfileRepository>.value(
          value: base.ownerProfileRepository,
        ),
        RepositoryProvider<WeightEntryRepository>.value(
          value: base.weightEntryRepository,
        ),
      ],
      child: BlocProvider<SubscriptionCubit>(
        create: (_) => SubscriptionCubit(base.subscriptionService),
        child: const MaterialApp(home: PetListScreen()),
      ),
    );
  }
}

class _FakeAuthRepository implements AccountAuthRepository {
  const _FakeAuthRepository();

  static const _user = AppUser(id: 'user-1', isAnonymous: true);

  @override
  Future<AppUser?> currentUser() async => _user;

  @override
  Future<AppUser> signInAnonymously() async => _user;

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() => Stream<AppUser?>.value(_user);

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  }) async =>
      AppUser(id: 'account-1', isAnonymous: false, email: email);

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      AppUser(id: 'account-1', isAnonymous: false, email: email);

  @override
  Future<AppUser> signInWithGoogle() async =>
      const AppUser(id: 'account-1', isAnonymous: false);

  @override
  Future<AppUser> signInWithApple() async =>
      const AppUser(id: 'account-1', isAnonymous: false);
}

class _FakePetRepository implements PetRepository {
  static const _pets = [
    Pet(
      id: EntityId('pet-1'),
      userId: EntityId('user-1'),
      name: 'Bella',
      species: 'Dog',
    ),
    Pet(
      id: EntityId('pet-2'),
      userId: EntityId('user-1'),
      name: 'Max',
      species: 'Cat',
    ),
  ];

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<Pet>> watchPets(EntityId userId) => Stream.value(_pets);

  @override
  Future<Pet?> getPet({
    required EntityId userId,
    required EntityId petId,
  }) async {
    for (final pet in _pets) {
      if (pet.id == petId) return pet;
    }
    return null;
  }

  @override
  Future<void> savePet(Pet pet) async {}

  @override
  Future<void> deletePet({
    required EntityId userId,
    required EntityId petId,
  }) async {}
}
