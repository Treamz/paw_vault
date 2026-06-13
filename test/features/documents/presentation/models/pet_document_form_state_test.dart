import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/presentation/models/pet_document_form_state.dart';

void main() {
  group('PetDocumentFormState', () {
    test('is valid with required fields set', () {
      const form = PetDocumentFormState(
        type: PetDocumentType.passport,
        title: 'EU Pet Passport',
      );

      final validation = form.validate();

      expect(validation.isValid, isTrue);
      expect(validation.errors, isEmpty);
    });

    test('requires a type', () {
      const form = PetDocumentFormState(title: 'Untyped document');

      final validation = form.validate();

      expect(validation.isValid, isFalse);
      expect(validation.errorFor('type'), isNotNull);
    });

    test('requires a non-empty title', () {
      const form = PetDocumentFormState(
        type: PetDocumentType.passport,
        title: '   ',
      );

      final validation = form.validate();

      expect(validation.errorFor('title'), isNotNull);
    });

    test('rejects a title longer than 200 characters', () {
      final form = PetDocumentFormState(
        type: PetDocumentType.passport,
        title: 'a' * 201,
      );

      final validation = form.validate();

      expect(validation.errorFor('title'), isNotNull);
    });

    test('rejects an issue date in the future', () {
      final form = PetDocumentFormState(
        type: PetDocumentType.passport,
        title: 'Passport',
        issueDate: DateTime(3000),
      );

      final validation = form.validate();

      expect(validation.errorFor('issueDate'), isNotNull);
    });

    test('rejects an issue date more than 100 years in the past', () {
      final form = PetDocumentFormState(
        type: PetDocumentType.passport,
        title: 'Passport',
        issueDate: DateTime(1800),
      );

      final validation = form.validate();

      expect(validation.errorFor('issueDate'), isNotNull);
    });

    test('rejects an expiry date before the issue date', () {
      final form = PetDocumentFormState(
        type: PetDocumentType.passport,
        title: 'Passport',
        issueDate: DateTime(2024, 6),
        expiryDate: DateTime(2024, 5),
      );

      final validation = form.validate();

      expect(validation.errorFor('expiryDate'), isNotNull);
    });

    test('allows an expiry date after the issue date', () {
      final form = PetDocumentFormState(
        type: PetDocumentType.passport,
        title: 'Passport',
        issueDate: DateTime(2024, 6),
        expiryDate: DateTime(2030, 6),
      );

      final validation = form.validate();

      expect(validation.isValid, isTrue);
    });

    test('rejects notes longer than 5000 characters', () {
      final form = PetDocumentFormState(
        type: PetDocumentType.passport,
        title: 'Passport',
        notes: 'n' * 5001,
      );

      final validation = form.validate();

      expect(validation.errorFor('notes'), isNotNull);
    });

    test('toDocument throws when invalid', () {
      const form = PetDocumentFormState();

      expect(
        () => form.toDocument(
          id: const EntityId('doc-1'),
          userId: const EntityId('user-1'),
          petId: const EntityId('pet-1'),
          fileUrl: Uri.parse('https://example.com/doc.pdf'),
          storagePath: 'users/user-1/pets/pet-1/documents/doc-1.pdf',
        ),
        throwsA(isA<PetDocumentFormValidationException>()),
      );
    });

    test('toDocument builds a trimmed document with storage details', () {
      final form = PetDocumentFormState(
        type: PetDocumentType.insurance,
        title: '  Pet insurance  ',
        issueDate: DateTime(2024, 1, 15),
        expiryDate: DateTime(2025, 1, 15),
        notes: '  annual policy  ',
      );

      final document = form.toDocument(
        id: const EntityId('doc-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        fileUrl: Uri.parse('https://example.com/doc.pdf'),
        storagePath: 'users/user-1/pets/pet-1/documents/doc-1.pdf',
      );

      expect(document.title, 'Pet insurance');
      expect(document.type, PetDocumentType.insurance);
      expect(document.fileUrl, Uri.parse('https://example.com/doc.pdf'));
      expect(
        document.storagePath,
        'users/user-1/pets/pet-1/documents/doc-1.pdf',
      );
      expect(document.issueDate, const DateOnly(year: 2024, month: 1, day: 15));
      expect(
        document.expiryDate,
        const DateOnly(year: 2025, month: 1, day: 15),
      );
      expect(document.notes, 'annual policy');
    });

    test('toDocument maps empty notes to null', () {
      const form = PetDocumentFormState(
        type: PetDocumentType.passport,
        title: 'Passport',
        notes: '   ',
      );

      final document = form.toDocument(
        id: const EntityId('doc-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        fileUrl: Uri.parse('https://example.com/doc.pdf'),
        storagePath: 'users/user-1/pets/pet-1/documents/doc-1.pdf',
      );

      expect(document.notes, isNull);
    });

    test('fromDocument round-trips editable fields', () {
      final document = PetDocument(
        id: const EntityId('doc-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        title: 'Passport',
        type: PetDocumentType.passport,
        fileUrl: Uri.parse('https://example.com/doc.pdf'),
        storagePath: 'users/user-1/pets/pet-1/documents/doc-1.pdf',
        issueDate: const DateOnly(year: 2024, month: 1, day: 15),
        expiryDate: const DateOnly(year: 2030, month: 1, day: 15),
        notes: 'valid passport',
      );

      final form = PetDocumentFormState.fromDocument(document);

      expect(form.type, PetDocumentType.passport);
      expect(form.title, 'Passport');
      expect(form.issueDate, DateTime.utc(2024, 1, 15));
      expect(form.expiryDate, DateTime.utc(2030, 1, 15));
      expect(form.notes, 'valid passport');
      expect(form.validate().isValid, isTrue);
    });
  });
}
