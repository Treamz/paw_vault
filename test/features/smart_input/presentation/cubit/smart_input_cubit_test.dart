import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';
import 'package:paw_vault/features/smart_input/presentation/cubit/smart_input_cubit.dart';

void main() {
  group('SmartInputCubit', () {
    test('submits text and emits the AI draft for review', () async {
      final draft = _draft();
      final repository = _FakeSmartInputRepository(draft: draft);
      final cubit = _cubit(repository);
      final states = <SmartInputState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.submit('Bella got her rabies shot today');
      await Future<void>.delayed(Duration.zero);

      expect(repository.createDraftInput, 'Bella got her rabies shot today');
      expect(states.first.status, SmartInputStatus.processing);
      expect(states.last.status, SmartInputStatus.review);
      expect(states.last.draft, draft);
      expect(states.last.hasDraft, isTrue);

      await subscription.cancel();
      await cubit.close();
    });

    test('rejects empty input without calling the repository', () async {
      final repository = _FakeSmartInputRepository(draft: _draft());
      final cubit = _cubit(repository);

      await cubit.submit('   ');

      expect(cubit.state.status, SmartInputStatus.failure);
      expect(repository.createDraftCallCount, isZero);

      await cubit.close();
    });

    test('emits failure when the AI repository throws', () async {
      final repository = _FakeSmartInputRepository(throwsOnCreate: true);
      final cubit = _cubit(repository);

      await cubit.submit('Bella got her rabies shot today');

      expect(cubit.state.status, SmartInputStatus.failure);
      expect(cubit.state.errorMessage, contains('ai failed'));

      await cubit.close();
    });

    test('confirmDraft saves the reviewed draft as a confirmed message',
        () async {
      final repository = _FakeSmartInputRepository(draft: _draft());
      final cubit = _cubit(repository);

      await cubit.submit('Bella got her rabies shot today');
      await cubit.confirmDraft('pet-1');

      final saved = repository.savedMessage;
      expect(saved, isNotNull);
      expect(saved!.status, SmartMessageStatus.confirmed);
      expect(saved.petId, const EntityId('pet-1'));
      expect(saved.userId, const EntityId('user-1'));
      expect(saved.detectedIntent, SmartMessageIntent.addVaccination);
      expect(saved.originalText, 'Bella got her rabies shot today');
      expect(cubit.state.status, SmartInputStatus.confirmed);
      expect(cubit.state.hasDraft, isFalse);

      await cubit.close();
    });

    test('confirmDraft does nothing when there is no draft', () async {
      final repository = _FakeSmartInputRepository(draft: _draft());
      final cubit = _cubit(repository);

      await cubit.confirmDraft('pet-1');

      expect(repository.saveCallCount, isZero);
      expect(cubit.state.status, SmartInputStatus.failure);

      await cubit.close();
    });

    test('dismissDraft clears the draft without saving', () async {
      final repository = _FakeSmartInputRepository(draft: _draft());
      final cubit = _cubit(repository);

      await cubit.submit('Bella got her rabies shot today');
      expect(cubit.state.hasDraft, isTrue);

      cubit.dismissDraft();

      expect(cubit.state.status, SmartInputStatus.idle);
      expect(cubit.state.draft, isNull);
      expect(repository.saveCallCount, isZero);

      await cubit.close();
    });

    test('confirmDraft emits failure when saving throws', () async {
      final repository = _FakeSmartInputRepository(
        draft: _draft(),
        throwsOnSave: true,
      );
      final cubit = _cubit(repository);

      await cubit.submit('Bella got her rabies shot today');
      await cubit.confirmDraft('pet-1');

      expect(cubit.state.status, SmartInputStatus.failure);
      // The draft is preserved so the user can retry confirming.
      expect(cubit.state.draft, isNotNull);

      await cubit.close();
    });
  });
}

SmartInputCubit _cubit(_FakeSmartInputRepository repository) {
  return SmartInputCubit(
    smartInputRepository: repository,
    authRepository: _FakeAuthRepository(
      currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
    ),
  );
}

SmartInputDraft _draft() {
  return const SmartInputDraft(
    originalText: 'Bella got her rabies shot today',
    requiresConfirmation: true,
    detectedIntent: SmartMessageIntent.addVaccination,
    confidence: 0.92,
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.currentUserValue});

  final AppUser? currentUserValue;

  @override
  Future<AppUser?> currentUser() async => currentUserValue;

  @override
  Future<AppUser> signInAnonymously() async =>
      const AppUser(id: 'signed-in-user', isAnonymous: true);

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() =>
      Stream<AppUser?>.value(currentUserValue);
}

class _FakeSmartInputRepository implements SmartInputRepository {
  _FakeSmartInputRepository({
    this.draft,
    this.throwsOnCreate = false,
    this.throwsOnSave = false,
  });

  final SmartInputDraft? draft;
  final bool throwsOnCreate;
  final bool throwsOnSave;

  int createDraftCallCount = 0;
  String? createDraftInput;
  int saveCallCount = 0;
  SmartMessage? savedMessage;

  @override
  Future<SmartInputDraft> createDraft(String input) async {
    createDraftCallCount++;
    createDraftInput = input;
    if (throwsOnCreate) {
      throw StateError('ai failed');
    }
    return draft!;
  }

  @override
  Future<void> deleteSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) async {}

  @override
  Future<SmartMessage?> getSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) async {
    return null;
  }

  @override
  Future<void> saveSmartMessage(SmartMessage message) async {
    saveCallCount++;
    if (throwsOnSave) {
      throw StateError('save failed');
    }
    savedMessage = message;
  }

  @override
  Stream<List<SmartMessage>> watchSmartMessages({
    required EntityId userId,
    required EntityId petId,
  }) {
    return const Stream<List<SmartMessage>>.empty();
  }
}
