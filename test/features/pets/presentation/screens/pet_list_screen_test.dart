import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/account_auth_repository.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/presentation/screens/pet_list_screen.dart';

void main() {
  group('PetListScreen', () {
    testWidgets('renders loading state', (tester) async {
      final initializeCompleter = Completer<void>();

      await tester.pumpWidget(
        _TestApp(
          petRepository: _FakePetRepository(
            initializeCompleter: initializeCompleter,
          ),
        ),
      );

      await tester.pump();

      expect(find.text('PawVault'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      initializeCompleter.complete();
    });

    testWidgets('renders empty state', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          petRepository: _FakePetRepository(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No pets yet'), findsOneWidget);
      expect(
        find.text(
          'Add your first pet profile to start building a health archive.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders populated state', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          petRepository: _FakePetRepository(
            watchedPets: const [
              Pet(
                id: EntityId('pet-1'),
                userId: EntityId('user-1'),
                name: 'Mochi',
                species: 'Cat',
                breed: 'Tabby',
              ),
              Pet(
                id: EntityId('pet-2'),
                userId: EntityId('user-1'),
                name: 'Biscuit',
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mochi'), findsOneWidget);
      expect(find.text('Cat - Tabby'), findsOneWidget);
      expect(find.text('Biscuit'), findsOneWidget);
      expect(find.text('Pet profile'), findsOneWidget);
      expect(find.byKey(const ValueKey('pet-pet-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('pet-pet-2')), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          petRepository: _FakePetRepository(throwsOnInitialize: true),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Could not load pets'), findsOneWidget);
      expect(find.textContaining('initialize failed'), findsOneWidget);
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.petRepository,
    AccountAuthRepository? authRepository,
  }) : authRepository = authRepository ?? const _FakeAuthRepository();

  final PetRepository petRepository;
  final AccountAuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<AccountAuthRepository>.value(value: authRepository),
        RepositoryProvider<PetRepository>.value(value: petRepository),
      ],
      child: const MaterialApp(
        home: PetListScreen(),
      ),
    );
  }
}

class _FakeAuthRepository implements AccountAuthRepository {
  const _FakeAuthRepository();

  @override
  Future<AppUser?> currentUser() async {
    return const AppUser(id: 'user-1', isAnonymous: true);
  }

  @override
  Future<AppUser> signInAnonymously() async {
    return const AppUser(id: 'user-1', isAnonymous: true);
  }

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() {
    return Stream<AppUser?>.value(
      const AppUser(id: 'user-1', isAnonymous: true),
    );
  }

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
  _FakePetRepository({
    this.watchedPets = const [],
    this.throwsOnInitialize = false,
    this.initializeCompleter,
  });

  final List<Pet> watchedPets;
  final bool throwsOnInitialize;
  final Completer<void>? initializeCompleter;

  @override
  Future<void> deletePet({
    required EntityId userId,
    required EntityId petId,
  }) async {}

  @override
  Future<Pet?> getPet({
    required EntityId userId,
    required EntityId petId,
  }) async {
    return null;
  }

  @override
  Future<void> initialize() async {
    if (initializeCompleter != null) {
      await initializeCompleter!.future;
    }

    if (throwsOnInitialize) {
      throw StateError('initialize failed');
    }
  }

  @override
  Future<void> savePet(Pet pet) async {}

  @override
  Stream<List<Pet>> watchPets(EntityId userId) {
    return Stream<List<Pet>>.value(watchedPets);
  }
}
