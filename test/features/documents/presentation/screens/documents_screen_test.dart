import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/presentation/screens/documents_screen.dart';

void main() {
  group('DocumentsScreen', () {
    testWidgets('shows the empty state when there are no documents',
        (tester) async {
      await tester.pumpWidget(_app(const []));
      await tester.pumpAndSettle();

      expect(find.text('No documents yet'), findsOneWidget);
    });

    testWidgets('renders documents when present', (tester) async {
      await tester.pumpWidget(_app([_document()]));
      await tester.pumpAndSettle();

      expect(find.text('Vaccination certificate'), findsOneWidget);
      expect(find.text('No documents yet'), findsNothing);
    });

    testWidgets('shows the issue date on the tile when present',
        (tester) async {
      final datedDocument = PetDocument(
        id: const EntityId('doc-3'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        title: 'Rabies certificate',
        type: PetDocumentType.vaccinationCertificate,
        fileUrl: Uri.parse('https://example.com/doc.pdf'),
        storagePath: 'users/user-1/pets/pet-1/documents/doc-3/original.pdf',
        issueDate: DateOnly.fromDateTime(DateTime(2026, 1, 5)),
      );

      await tester.pumpWidget(_app([datedDocument, _document()]));
      await tester.pumpAndSettle();

      expect(
        find.text('Vaccination Certificate · Jan 5, 2026'),
        findsOneWidget,
      );
      // The undated document keeps the plain type label on its tile (the
      // filter chip bar also carries the type name, so scope to tiles).
      expect(
        find.widgetWithText(ListTile, 'Vaccination Certificate'),
        findsOneWidget,
      );
    });

    testWidgets('filters the list to the selected document type',
        (tester) async {
      final passport = PetDocument(
        id: const EntityId('doc-passport'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        title: 'EU Pet Passport',
        type: PetDocumentType.passport,
        fileUrl: Uri.parse('https://example.com/passport.pdf'),
        storagePath: 'users/user-1/pets/pet-1/documents/passport.pdf',
      );

      await tester.pumpWidget(_app([_document(), passport]));
      await tester.pumpAndSettle();

      // Chips for All + the two present types; no chip for absent types.
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Passport'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Insurance'), findsNothing);

      await tester.tap(find.widgetWithText(FilterChip, 'Passport'));
      await tester.pumpAndSettle();

      expect(find.text('EU Pet Passport'), findsOneWidget);
      expect(find.text('Vaccination certificate'), findsNothing);

      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pumpAndSettle();

      expect(find.text('EU Pet Passport'), findsOneWidget);
      expect(find.text('Vaccination certificate'), findsOneWidget);
    });

    testWidgets('always shows the standard type icon, even for photos',
        (tester) async {
      final imageDocument = PetDocument(
        id: const EntityId('doc-2'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        title: 'Scanned receipt',
        type: PetDocumentType.receipt,
        fileUrl: Uri.parse('https://example.com/doc.jpg'),
        storagePath: 'users/user-1/pets/pet-1/documents/doc-2/original.jpg',
      );

      await tester.pumpWidget(_app([_document(), imageDocument]));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
      expect(find.byType(CircleAvatar), findsNWidgets(2));
    });
  });
}

Widget _app(List<PetDocument> documents) {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: _FakeAuthRepository()),
      RepositoryProvider<DocumentRepository>.value(
        value: _FakeDocumentRepository(documents),
      ),
    ],
    child: const MaterialApp(home: DocumentsScreen(petId: 'pet-1')),
  );
}

PetDocument _document() => PetDocument(
      id: const EntityId('doc-1'),
      userId: const EntityId('user-1'),
      petId: const EntityId('pet-1'),
      title: 'Vaccination certificate',
      type: PetDocumentType.vaccinationCertificate,
      fileUrl: Uri.parse('https://example.com/doc.pdf'),
      storagePath: 'users/user-1/pets/pet-1/documents/doc-1.pdf',
    );

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

class _FakeDocumentRepository implements DocumentRepository {
  _FakeDocumentRepository(this.documents);

  final List<PetDocument> documents;

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PetDocument>> watchDocuments({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream<List<PetDocument>>.value(documents);

  @override
  Future<PetDocument?> getDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async =>
      null;

  @override
  Future<void> saveDocument(PetDocument document) async {}

  @override
  Future<void> deleteDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async {}
}
