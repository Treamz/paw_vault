import 'package:flutter_test/flutter_test.dart';
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
      final cubit = SmartInputCubit(repository);
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
      final cubit = SmartInputCubit(repository);

      await cubit.submit('   ');

      expect(cubit.state.status, SmartInputStatus.failure);
      expect(repository.createDraftCallCount, isZero);

      await cubit.close();
    });

    test('emits failure when the AI repository throws', () async {
      final repository = _FakeSmartInputRepository(throwsOnCreate: true);
      final cubit = SmartInputCubit(repository);

      await cubit.submit('Bella got her rabies shot today');

      expect(cubit.state.status, SmartInputStatus.failure);
      expect(cubit.state.errorMessage, contains('ai failed'));

      await cubit.close();
    });
  });
}

SmartInputDraft _draft() {
  return const SmartInputDraft(
    originalText: 'Bella got her rabies shot today',
    requiresConfirmation: true,
    detectedIntent: SmartMessageIntent.addVaccination,
    confidence: 0.92,
  );
}

class _FakeSmartInputRepository implements SmartInputRepository {
  _FakeSmartInputRepository({
    this.draft,
    this.throwsOnCreate = false,
  });

  final SmartInputDraft? draft;
  final bool throwsOnCreate;

  int createDraftCallCount = 0;
  String? createDraftInput;

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
  Future<void> saveSmartMessage(SmartMessage message) async {}

  @override
  Stream<List<SmartMessage>> watchSmartMessages({
    required EntityId userId,
    required EntityId petId,
  }) {
    return const Stream<List<SmartMessage>>.empty();
  }
}
