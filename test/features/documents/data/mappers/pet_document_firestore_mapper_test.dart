import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/features/documents/data/mappers/pet_document_firestore_mapper.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';

void main() {
  group('PetDocumentFirestoreMapper', () {
    test('maps a complete PetDocument to Firestore data', () {
      final document = _document();

      final data = PetDocumentFirestoreMapper.toFirestore(document);

      expect(data['userId'], 'user-1');
      expect(data['petId'], 'pet-1');
      expect(data['title'], 'Rabies certificate');
      expect(data['type'], 'vaccinationCertificate');
      expect(data['fileUrl'], 'https://example.com/rabies.pdf');
      expect(
        data['storagePath'],
        'users/user-1/pets/pet-1/documents/doc-1/original.pdf',
      );
      expect(data['extractedText'], 'Rabies vaccine certificate');
      expect(data['extractedData'], {'vaccineName': 'rabies'});
      expect(data['issueDate'], '2026-01-02');
      expect(data['expiryDate'], '2027-01-02');
      expect(data['notes'], 'Reviewed by owner.');
      expect(data['linkedEventId'], 'event-1');
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('maps Firestore data to a complete PetDocument', () {
      final data = PetDocumentFirestoreMapper.toFirestore(_document());

      final document = PetDocumentFirestoreMapper.fromFirestore(
        id: const EntityId('doc-1'),
        data: data,
      );

      expect(document.id, const EntityId('doc-1'));
      expect(document.userId, const EntityId('user-1'));
      expect(document.petId, const EntityId('pet-1'));
      expect(document.title, 'Rabies certificate');
      expect(document.type, PetDocumentType.vaccinationCertificate);
      expect(document.fileUrl, Uri.parse('https://example.com/rabies.pdf'));
      expect(
        document.storagePath,
        'users/user-1/pets/pet-1/documents/doc-1/original.pdf',
      );
      expect(document.extractedText, 'Rabies vaccine certificate');
      expect(document.extractedData, {'vaccineName': 'rabies'});
      expect(document.issueDate, const DateOnly(year: 2026, month: 1, day: 2));
      expect(document.expiryDate, const DateOnly(year: 2027, month: 1, day: 2));
      expect(document.notes, 'Reviewed by owner.');
      expect(document.linkedEventId, const EntityId('event-1'));
      expect(document.createdAt, UtcDateTime(DateTime.utc(2026, 1, 2, 3, 4)));
      expect(document.updatedAt, UtcDateTime(DateTime.utc(2026, 1, 3, 3, 4)));
    });

    test('round-trips a complete PetDocument through Firestore data', () {
      final original = _document();

      final roundTripped = PetDocumentFirestoreMapper.fromFirestore(
        id: original.id,
        data: PetDocumentFirestoreMapper.toFirestore(original),
      );

      expect(roundTripped.id, original.id);
      expect(roundTripped.userId, original.userId);
      expect(roundTripped.petId, original.petId);
      expect(roundTripped.title, original.title);
      expect(roundTripped.type, original.type);
      expect(roundTripped.fileUrl, original.fileUrl);
      expect(roundTripped.storagePath, original.storagePath);
      expect(roundTripped.extractedText, original.extractedText);
      expect(roundTripped.extractedData, original.extractedData);
      expect(roundTripped.issueDate, original.issueDate);
      expect(roundTripped.expiryDate, original.expiryDate);
      expect(roundTripped.notes, original.notes);
      expect(roundTripped.linkedEventId, original.linkedEventId);
      expect(roundTripped.createdAt, original.createdAt);
      expect(roundTripped.updatedAt, original.updatedAt);
    });

    test('uses defaults for missing optional fields', () {
      final document = PetDocumentFirestoreMapper.fromFirestore(
        id: const EntityId('doc-1'),
        data: const {
          'userId': 'user-1',
          'petId': 'pet-1',
          'title': 'Receipt',
          'type': 'receipt',
          'fileUrl': 'https://example.com/receipt.pdf',
          'storagePath': 'users/user-1/pets/pet-1/documents/doc-1/original.pdf',
        },
      );

      expect(document.extractedText, isNull);
      expect(document.extractedData, isEmpty);
      expect(document.issueDate, isNull);
      expect(document.expiryDate, isNull);
      expect(document.notes, isNull);
      expect(document.linkedEventId, isNull);
      expect(document.createdAt, isNull);
      expect(document.updatedAt, isNull);
    });

    test('round-trips a document without a file attachment', () {
      const document = PetDocument(
        id: EntityId('doc-1'),
        userId: EntityId('user-1'),
        petId: EntityId('pet-1'),
        title: 'Metadata only',
        type: PetDocumentType.other,
      );

      final data = PetDocumentFirestoreMapper.toFirestore(document);
      expect(data.containsKey('fileUrl'), isFalse);
      expect(data.containsKey('storagePath'), isFalse);

      final restored = PetDocumentFirestoreMapper.fromFirestore(
        id: document.id,
        data: data,
      );
      expect(restored.fileUrl, isNull);
      expect(restored.storagePath, isNull);
      expect(restored.hasFile, isFalse);
      expect(restored.title, 'Metadata only');
    });

    test('rejects invalid required fields', () {
      expect(
        () => PetDocumentFirestoreMapper.fromFirestore(
          id: const EntityId('doc-1'),
          data: const {
            'userId': 'user-1',
            'petId': 'pet-1',
            'title': 'Receipt',
            'type': 'unknownType',
            'fileUrl': 'https://example.com/receipt.pdf',
            'storagePath': 'path',
          },
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });

    test('rejects invalid extracted data', () {
      expect(
        () => PetDocumentFirestoreMapper.fromFirestore(
          id: const EntityId('doc-1'),
          data: const {
            'userId': 'user-1',
            'petId': 'pet-1',
            'title': 'Receipt',
            'type': 'receipt',
            'fileUrl': 'https://example.com/receipt.pdf',
            'storagePath': 'path',
            'extractedData': ['not', 'a', 'map'],
          },
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });
  });
}

PetDocument _document() {
  return PetDocument(
    id: const EntityId('doc-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    title: 'Rabies certificate',
    type: PetDocumentType.vaccinationCertificate,
    fileUrl: Uri.parse('https://example.com/rabies.pdf'),
    storagePath: 'users/user-1/pets/pet-1/documents/doc-1/original.pdf',
    extractedText: 'Rabies vaccine certificate',
    extractedData: const {'vaccineName': 'rabies'},
    issueDate: const DateOnly(year: 2026, month: 1, day: 2),
    expiryDate: const DateOnly(year: 2027, month: 1, day: 2),
    notes: 'Reviewed by owner.',
    linkedEventId: const EntityId('event-1'),
    createdAt: UtcDateTime(DateTime.utc(2026, 1, 2, 3, 4)),
    updatedAt: UtcDateTime(DateTime.utc(2026, 1, 3, 3, 4)),
  );
}
