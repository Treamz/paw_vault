import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/features/documents/domain/entities/document_attachment.dart';
import 'package:paw_vault/features/smart_input/data/mappers/smart_message_firestore_mapper.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';

void main() {
  group('SmartMessageFirestoreMapper attachments', () {
    test('round-trips every attachment of a scanned entry', () {
      // The reported bug: a scan attached two files and History showed none.
      final message = _message(
        attachments: [
          DocumentAttachment(
            fileUrl: Uri.parse('https://example.com/attachment_0.png'),
            storagePath: 'users/user-1/pets/pet-1/documents/doc-1/'
                'attachment_0.png',
          ),
          DocumentAttachment(
            fileUrl: Uri.parse('https://example.com/attachment_1.pdf'),
            storagePath: 'users/user-1/pets/pet-1/documents/doc-1/'
                'attachment_1.pdf',
          ),
        ],
      );

      final data = SmartMessageFirestoreMapper.toFirestore(message);
      expect(data['attachments'], hasLength(2));

      final restored = SmartMessageFirestoreMapper.fromFirestore(
        id: const EntityId('message-1'),
        data: data,
      );

      expect(restored.attachments, message.attachments);
      expect(restored.imageAttachments, hasLength(1));
      expect(restored.imageAttachments.single.fileExtension, 'png');
    });

    test('a typed entry writes no attachments field and reads back empty', () {
      // Entries saved before attachment support, and every typed note, have
      // no such field at all — that must not be a mapping error.
      final data = SmartMessageFirestoreMapper.toFirestore(_message());

      expect(data.containsKey('attachments'), isFalse);
      expect(
        SmartMessageFirestoreMapper.fromFirestore(
          id: const EntityId('message-1'),
          data: data,
        ).attachments,
        isEmpty,
      );
    });

    test('rejects a malformed attachment rather than dropping it', () {
      expect(
        () => SmartMessageFirestoreMapper.fromFirestore(
          id: const EntityId('message-1'),
          data: {
            ...SmartMessageFirestoreMapper.toFirestore(_message()),
            'attachments': [
              {'storagePath': 'a.png'},
            ],
          },
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });
  });

  group('SmartMessageFirestoreMapper', () {
    test('maps a complete SmartMessage to Firestore data', () {
      final message = _message();

      final data = SmartMessageFirestoreMapper.toFirestore(message);

      expect(data['userId'], 'user-1');
      expect(data['petId'], 'pet-1');
      expect(data['originalText'], 'Add rabies vaccine from today.');
      expect(data['detectedIntent'], 'addVaccination');
      expect(data['extractedData'], {'vaccineName': 'rabies'});
      expect(data['suggestedActions'], [
        {
          'type': 'createTimelineEvent',
          'payload': {'eventType': 'vaccination'},
        },
        {
          'type': 'createReminder',
          'payload': {'repeatType': 'yearly'},
        },
      ]);
      expect(data['confidence'], 0.82);
      expect(data['status'], 'awaitingConfirmation');
      expect(data['createdAt'], isA<Timestamp>());
    });

    test('maps Firestore data to a complete SmartMessage', () {
      final data = SmartMessageFirestoreMapper.toFirestore(_message());

      final message = SmartMessageFirestoreMapper.fromFirestore(
        id: const EntityId('message-1'),
        data: data,
      );

      expect(message.id, const EntityId('message-1'));
      expect(message.userId, const EntityId('user-1'));
      expect(message.petId, const EntityId('pet-1'));
      expect(message.originalText, 'Add rabies vaccine from today.');
      expect(message.detectedIntent, SmartMessageIntent.addVaccination);
      expect(message.extractedData, {'vaccineName': 'rabies'});
      expect(message.suggestedActions, hasLength(2));
      expect(
        message.suggestedActions.first.type,
        SmartSuggestedActionType.createTimelineEvent,
      );
      expect(
        message.suggestedActions.first.payload,
        {'eventType': 'vaccination'},
      );
      expect(
        message.suggestedActions.last.type,
        SmartSuggestedActionType.createReminder,
      );
      expect(message.suggestedActions.last.payload, {'repeatType': 'yearly'});
      expect(message.confidence, 0.82);
      expect(message.status, SmartMessageStatus.awaitingConfirmation);
      expect(message.createdAt, UtcDateTime(DateTime.utc(2026, 1, 2, 3, 4)));
    });

    test('round-trips a complete SmartMessage through Firestore data', () {
      final original = _message();

      final roundTripped = SmartMessageFirestoreMapper.fromFirestore(
        id: original.id,
        data: SmartMessageFirestoreMapper.toFirestore(original),
      );

      expect(roundTripped.id, original.id);
      expect(roundTripped.userId, original.userId);
      expect(roundTripped.petId, original.petId);
      expect(roundTripped.originalText, original.originalText);
      expect(roundTripped.detectedIntent, original.detectedIntent);
      expect(roundTripped.extractedData, original.extractedData);
      expect(roundTripped.suggestedActions, hasLength(2));
      expect(
        roundTripped.suggestedActions.first.type,
        original.suggestedActions.first.type,
      );
      expect(
        roundTripped.suggestedActions.first.payload,
        original.suggestedActions.first.payload,
      );
      expect(
        roundTripped.suggestedActions.last.type,
        original.suggestedActions.last.type,
      );
      expect(
        roundTripped.suggestedActions.last.payload,
        original.suggestedActions.last.payload,
      );
      expect(roundTripped.confidence, original.confidence);
      expect(roundTripped.status, original.status);
      expect(roundTripped.createdAt, original.createdAt);
    });

    test('uses defaults for missing optional fields', () {
      final message = SmartMessageFirestoreMapper.fromFirestore(
        id: const EntityId('message-1'),
        data: const {
          'userId': 'user-1',
          'petId': 'pet-1',
          'originalText': 'Add note.',
          'detectedIntent': 'addNote',
          'confidence': 1,
          'status': 'draft',
        },
      );

      expect(message.extractedData, isEmpty);
      expect(message.suggestedActions, isEmpty);
      expect(message.createdAt, isNull);
      expect(message.confidence, 1.0);
    });

    test('rejects invalid required fields', () {
      expect(
        () => SmartMessageFirestoreMapper.fromFirestore(
          id: const EntityId('message-1'),
          data: const {
            'userId': 'user-1',
            'petId': 'pet-1',
            'originalText': 'Add note.',
            'detectedIntent': 'notAnIntent',
            'confidence': 1,
            'status': 'draft',
          },
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });

    test('rejects invalid extracted data', () {
      expect(
        () => SmartMessageFirestoreMapper.fromFirestore(
          id: const EntityId('message-1'),
          data: const {
            'userId': 'user-1',
            'petId': 'pet-1',
            'originalText': 'Add note.',
            'detectedIntent': 'addNote',
            'extractedData': ['not', 'a', 'map'],
            'confidence': 1,
            'status': 'draft',
          },
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });

    test('rejects invalid suggested actions', () {
      expect(
        () => SmartMessageFirestoreMapper.fromFirestore(
          id: const EntityId('message-1'),
          data: const {
            'userId': 'user-1',
            'petId': 'pet-1',
            'originalText': 'Add note.',
            'detectedIntent': 'addNote',
            'confidence': 1,
            'status': 'draft',
            'suggestedActions': [
              {
                'type': 'notAnAction',
                'payload': {},
              },
            ],
          },
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });
  });
}

SmartMessage _message({List<DocumentAttachment> attachments = const []}) {
  return SmartMessage(
    id: const EntityId('message-1'),
    attachments: attachments,
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    originalText: 'Add rabies vaccine from today.',
    detectedIntent: SmartMessageIntent.addVaccination,
    extractedData: const {'vaccineName': 'rabies'},
    suggestedActions: const [
      SmartSuggestedAction(
        type: SmartSuggestedActionType.createTimelineEvent,
        payload: {'eventType': 'vaccination'},
      ),
      SmartSuggestedAction(
        type: SmartSuggestedActionType.createReminder,
        payload: {'repeatType': 'yearly'},
      ),
    ],
    confidence: 0.82,
    status: SmartMessageStatus.awaitingConfirmation,
    createdAt: UtcDateTime(DateTime.utc(2026, 1, 2, 3, 4)),
  );
}
