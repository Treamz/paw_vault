import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';
import 'package:paw_vault/features/smart_input/presentation/screens/smart_input_screen.dart';

void main() {
  group('SmartInputScreen', () {
    testWidgets('renders the AI disclaimer, analyze action, and empty history',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('AI-assisted organizing'), findsOneWidget);
      expect(find.text('Analyze'), findsOneWidget);
      expect(find.text('Attach document or photo'), findsOneWidget);
      expect(find.text('No saved entries yet.'), findsOneWidget);
    });
  });
}

Widget _app() {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: _FakeAuthRepository()),
      RepositoryProvider<SmartInputRepository>.value(
        value: _FakeSmartInputRepository(),
      ),
    ],
    child: const MaterialApp(home: SmartInputScreen(petId: 'pet-1')),
  );
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AppUser?> currentUser() async =>
      const AppUser(id: 'user-1', isAnonymous: true);

  @override
  Future<AppUser> signInAnonymously() async =>
      const AppUser(id: 'user-1', isAnonymous: true);

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() => Stream<AppUser?>.value(
        const AppUser(id: 'user-1', isAnonymous: true),
      );
}

class _FakeSmartInputRepository implements SmartInputRepository {
  @override
  Future<SmartInputDraft> createDraft(String input) async =>
      SmartInputDraft(originalText: input, requiresConfirmation: true);

  @override
  Stream<List<SmartMessage>> watchSmartMessages({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream<List<SmartMessage>>.value(const []);

  @override
  Future<SmartMessage?> getSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) async =>
      null;

  @override
  Future<void> saveSmartMessage(SmartMessage message) async {}

  @override
  Future<void> deleteSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) async {}
}
