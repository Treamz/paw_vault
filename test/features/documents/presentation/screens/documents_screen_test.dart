import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/domain/entities/document_attachment.dart';
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
      // A document with no issue date says so, rather than silently showing
      // just its type: that is what left its place in the list unexplained.
      expect(
        find.text('Vaccination Certificate · No date'),
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

    testWidgets('keeps the standard type icon in the leading slot',
        (tester) async {
      // A deliberate earlier choice: type icons keep the list scannable, so
      // the attached photo must not take the leading circle over. It gets a
      // thumbnail on the trailing edge instead.
      await tester.pumpWidget(_app([_document(), _imageDocument()]));
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsNWidgets(2));
      for (final avatar in find.byType(CircleAvatar).evaluate()) {
        expect(
          find.descendant(
            of: find.byWidget(avatar.widget),
            matching: find.byType(Image),
          ),
          findsNothing,
          reason: 'the leading circle shows an icon, not the photo',
        );
      }
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
      expect(find.byIcon(Icons.vaccines), findsOneWidget);
    });

    testWidgets('shows a thumbnail of an attached photo on its row',
        (tester) async {
      // Reported twice by QA: opening a document left a blank box for a
      // couple of seconds with no hint anything was attached. The row
      // showing the photo is both the hint and what warms the cache.
      await tester.pumpWidget(_app([_imageDocument()]));
      await tester.pumpAndSettle();

      final row = find.byKey(const ValueKey('document-doc-2'));
      expect(
        find.descendant(of: row, matching: find.byType(CachedNetworkImage)),
        findsOneWidget,
      );
    });

    testWidgets('a PDF-only document gets no thumbnail but still says so',
        (tester) async {
      // Nothing to show for a PDF, so the paperclip has to carry it.
      await tester.pumpWidget(_app([_document()]));
      await tester.pumpAndSettle();

      final row = find.byKey(const ValueKey('document-doc-1'));
      expect(
        find.descendant(of: row, matching: find.byType(CachedNetworkImage)),
        findsNothing,
      );
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
      expect(find.text('1 file'), findsOneWidget);
    });

    testWidgets('counts every attached file on the row', (tester) async {
      await tester.pumpWidget(
        _app([
          PetDocument(
            id: const EntityId('doc-3'),
            userId: const EntityId('user-1'),
            petId: const EntityId('pet-1'),
            title: 'Two-page lab result',
            type: PetDocumentType.labResult,
            attachments: [
              DocumentAttachment(
                fileUrl: Uri.parse('https://example.com/a.jpg'),
                storagePath: 'users/user-1/pets/pet-1/documents/doc-3/a.jpg',
              ),
              DocumentAttachment(
                fileUrl: Uri.parse('https://example.com/b.jpg'),
                storagePath: 'users/user-1/pets/pet-1/documents/doc-3/b.jpg',
              ),
            ],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 files'), findsOneWidget);
    });

    testWidgets('a document with no file says nothing about files',
        (tester) async {
      await tester.pumpWidget(
        _app([
          const PetDocument(
            id: EntityId('doc-4'),
            userId: EntityId('user-1'),
            petId: EntityId('pet-1'),
            title: 'Metadata only',
            type: PetDocumentType.other,
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.attach_file), findsNothing);
      expect(find.textContaining('file'), findsNothing);
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

PetDocument _imageDocument() => PetDocument(
      id: const EntityId('doc-2'),
      userId: const EntityId('user-1'),
      petId: const EntityId('pet-1'),
      title: 'Scanned receipt',
      type: PetDocumentType.receipt,
      fileUrl: Uri.parse('https://example.com/doc.jpg'),
      storagePath: 'users/user-1/pets/pet-1/documents/doc-2/original.jpg',
    );

PetDocument _document({Uri? fileUrl, String? storagePath}) => PetDocument(
      id: const EntityId('doc-1'),
      userId: const EntityId('user-1'),
      petId: const EntityId('pet-1'),
      title: 'Vaccination certificate',
      type: PetDocumentType.vaccinationCertificate,
      fileUrl: fileUrl ?? Uri.parse('https://example.com/doc.pdf'),
      storagePath: storagePath ?? 'users/user-1/pets/pet-1/documents/doc-1.pdf',
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
