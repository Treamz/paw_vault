import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/analytics/data/services/noop_analytics_service.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/domain/entities/document_attachment.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';
import 'package:paw_vault/features/smart_input/presentation/screens/smart_input_screen.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';

void main() {
  group('SmartInputScreen', () {
    testWidgets('renders the AI disclaimer, analyze action, and empty history',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('AI-assisted organizing'), findsOneWidget);
      expect(find.text('Analyze'), findsWidgets);
      expect(find.text('Attach document or photo'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('capitalizes sentences in the input field', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textCapitalization, TextCapitalization.sentences);
    });

    testWidgets('shows a thumbnail in History for an entry with a photo',
        (tester) async {
      // The reported bug: files attached in Smart Input showed up nowhere in
      // History, which rendered the same AI glyph for every entry.
      await tester.pumpWidget(
        _app(
          history: [
            _message(
              attachments: [
                DocumentAttachment(
                  fileUrl: Uri.parse('https://example.com/attachment_0.png'),
                  storagePath: 'users/user-1/pets/pet-1/documents/doc-1/'
                      'attachment_0.png',
                ),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      final tile = find.byKey(const ValueKey('smart-message-message-1'));
      expect(tile, findsOneWidget);
      expect(
        find.descendant(of: tile, matching: find.byType(CachedNetworkImage)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: tile,
          matching: find.byIcon(Icons.auto_awesome),
        ),
        findsNothing,
      );
    });

    testWidgets('marks a History entry whose only file is a PDF',
        (tester) async {
      // A PDF cannot be thumbnailed, but the row must still say a file is
      // attached rather than looking like a typed note.
      await tester.pumpWidget(
        _app(
          history: [
            _message(
              attachments: [
                DocumentAttachment(
                  fileUrl: Uri.parse('https://example.com/attachment_0.pdf'),
                  storagePath: 'users/user-1/pets/pet-1/documents/doc-1/'
                      'attachment_0.pdf',
                ),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      final tile = find.byKey(const ValueKey('smart-message-message-1'));
      expect(
        find.descendant(of: tile, matching: find.byIcon(Icons.attach_file)),
        findsOneWidget,
      );
    });

    testWidgets('keeps the AI glyph for a typed History entry', (tester) async {
      await tester.pumpWidget(_app(history: [_message()]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      final tile = find.byKey(const ValueKey('smart-message-message-1'));
      expect(
        find.descendant(of: tile, matching: find.byIcon(Icons.auto_awesome)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tile, matching: find.byType(CachedNetworkImage)),
        findsNothing,
      );
    });

    testWidgets('shows the draft above the input with a confirmation notice',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'Bella got her rabies shot today',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Analyze'));
      await tester.pumpAndSettle();

      expect(find.text('AI draft'), findsOneWidget);
      expect(
        find.text('Nothing is saved until you confirm. Correct or add '
            'details below.'),
        findsOneWidget,
      );
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      expect(find.text('Add detail'), findsOneWidget);

      // The draft renders above the text input.
      final draftY = tester.getTopLeft(find.text('AI draft')).dy;
      final inputY = tester.getTopLeft(find.byType(TextField)).dy;
      expect(draftY, lessThan(inputY));
    });
  });
}

SmartMessage _message({List<DocumentAttachment> attachments = const []}) {
  return SmartMessage(
    id: const EntityId('message-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    originalText: 'Scanned document: Rabies certificate',
    detectedIntent: SmartMessageIntent.addNote,
    attachments: attachments,
    confidence: 0.9,
    status: SmartMessageStatus.confirmed,
  );
}

Widget _app({List<SmartMessage> history = const []}) {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: _FakeAuthRepository()),
      RepositoryProvider<AnalyticsService>.value(
        value: const NoopAnalyticsService(),
      ),
      RepositoryProvider<SmartInputRepository>.value(
        value: _FakeSmartInputRepository(messages: history),
      ),
      RepositoryProvider<TimelineRepository>.value(
        value: _FakeTimelineRepository(),
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
  _FakeSmartInputRepository({this.messages = const []});

  final List<SmartMessage> messages;

  @override
  Future<SmartInputDraft> createDraft(String input) async =>
      SmartInputDraft(originalText: input, requiresConfirmation: true);

  @override
  Stream<List<SmartMessage>> watchSmartMessages({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream<List<SmartMessage>>.value(messages);

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

class _FakeTimelineRepository implements TimelineRepository {
  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PetEvent>> watchEvents({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream<List<PetEvent>>.value(const []);

  @override
  Future<PetEvent?> getEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async =>
      null;

  @override
  Future<void> saveEvent(PetEvent event) async {}

  @override
  Future<void> deleteEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async {}
}
