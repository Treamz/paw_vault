import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/domain/services/document_file_opener.dart';
import 'package:paw_vault/features/documents/presentation/screens/documents_screen.dart';

/// The document list beside the document it selects, which the app shows on
/// a surface big enough for both. See `hasRoomForTwoPanes`.
void main() {
  const duoUnfolded = Size(951, 669);
  const phone = Size(440, 956);

  Future<void> pumpAt(WidgetTester tester, Size surface) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
  }

  Finder inDetails(String text) => find.descendant(
        of: find.byType(DocumentDetailsView),
        matching: find.text(text),
      );

  group('DocumentsScreen on a wide surface', () {
    testWidgets('reads a document beside the list, with nothing tapped', (
      tester,
    ) async {
      await pumpAt(tester, duoUnfolded);

      expect(find.byType(DocumentDetailsView), findsOneWidget);
      expect(inDetails('Rabies certificate'), findsOneWidget);
    });

    testWidgets('swaps the pane without covering the list', (tester) async {
      await pumpAt(tester, duoUnfolded);

      await tester.tap(find.byKey(const ValueKey('document-doc-2')));
      await tester.pumpAndSettle();

      expect(inDetails('Blood panel'), findsOneWidget);
      // The whole point of the pane: the list it was picked from stays put,
      // where a sheet would have covered it.
      expect(find.byKey(const ValueKey('document-doc-1')), findsOneWidget);
    });
  });

  group('DocumentsScreen on a phone', () {
    testWidgets('shows no pane, so a tap still opens the sheet', (
      tester,
    ) async {
      await pumpAt(tester, phone);

      // Only the absence is asserted here. Opening the sheet goes through
      // `context.router`, which this harness has no AutoRouter for, and that
      // is the screen's own arrangement rather than anything to do with
      // panes.
      expect(find.byType(DocumentDetailsView), findsNothing);
      expect(find.byKey(const ValueKey('document-doc-1')), findsOneWidget);
    });
  });
}

Widget _app() {
  final base = AppDependencies.localFirst();

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: _FakeAuthRepository()),
      RepositoryProvider<DocumentRepository>.value(
        value: _FakeDocumentRepository(),
      ),
      RepositoryProvider<DocumentFileOpener>.value(
        value: base.documentFileOpener,
      ),
    ],
    child: const MaterialApp(home: DocumentsScreen(petId: 'pet-1')),
  );
}

PetDocument _document(String id, String title) => PetDocument(
      id: EntityId(id),
      userId: const EntityId('user-1'),
      petId: const EntityId('pet-1'),
      title: title,
      type: PetDocumentType.vaccinationCertificate,
      issueDate: const DateOnly(year: 2026, month: 5, day: 2),
    );

class _FakeAuthRepository implements AuthRepository {
  static const _user = AppUser(id: 'user-1', isAnonymous: true);

  @override
  Future<AppUser?> currentUser() async => _user;

  @override
  Future<AppUser> signInAnonymously() async => _user;

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() => Stream<AppUser?>.value(_user);
}

class _FakeDocumentRepository implements DocumentRepository {
  final _documents = [
    _document('doc-1', 'Rabies certificate'),
    _document('doc-2', 'Blood panel'),
  ];

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PetDocument>> watchDocuments({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream.value(_documents);

  @override
  Future<void> saveDocument(PetDocument document) async {}

  @override
  Future<void> deleteDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async {}

  @override
  Future<PetDocument?> getDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async {
    for (final document in _documents) {
      if (document.id == documentId) return document;
    }
    return null;
  }
}
