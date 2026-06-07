import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/presentation/models/pet_event_form_state.dart';

void main() {
  group('PetEventFormState', () {
    test('fromEvent creates form state from event entity', () {
      final event = PetEvent(
        id: const EntityId('event-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        type: PetEventType.vaccination,
        title: 'Annual vaccination',
        description: 'Rabies shot',
        date: UtcDateTime(DateTime(2024, 1, 15)),
        nextReminderDate: UtcDateTime(DateTime(2025, 1, 15)),
        attachments: [Uri.parse('https://example.com/cert.pdf')],
        source: PetEventSource.manual,
      );

      final formState = PetEventFormState.fromEvent(event);

      expect(formState.type, PetEventType.vaccination);
      expect(formState.title, 'Annual vaccination');
      expect(formState.description, 'Rabies shot');
      expect(formState.date?.toUtc(), DateTime(2024, 1, 15).toUtc());
      expect(
          formState.nextReminderDate?.toUtc(), DateTime(2025, 1, 15).toUtc());
      expect(formState.attachments, ['https://example.com/cert.pdf']);
    });

    test('copyWith updates specified fields only', () {
      const formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Original title',
        date: null,
      );

      final updated = formState.copyWith(
        title: 'Updated title',
        date: DateTime(2024, 1, 15),
      );

      expect(updated.type, PetEventType.vaccination);
      expect(updated.title, 'Updated title');
      expect(updated.date, DateTime(2024, 1, 15));
    });

    test('validate returns valid when all required fields are provided', () {
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Annual vaccination',
        date: DateTime(2024, 1, 15),
      );

      final validation = formState.validate();

      expect(validation.isValid, isTrue);
      expect(validation.errors, isEmpty);
    });

    test('validate returns error when type is missing', () {
      final formState = PetEventFormState(
        title: 'Title',
        date: DateTime(2024, 1, 15),
      );

      final validation = formState.validate();

      expect(validation.isValid, isFalse);
      expect(validation.errorFor('type'), 'Event type is required');
    });

    test('validate returns error when title is empty', () {
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: '',
        date: DateTime(2024, 1, 15),
      );

      final validation = formState.validate();

      expect(validation.isValid, isFalse);
      expect(validation.errorFor('title'), 'Event title is required');
    });

    test('validate returns error when title is whitespace only', () {
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: '   ',
        date: DateTime(2024, 1, 15),
      );

      final validation = formState.validate();

      expect(validation.isValid, isFalse);
      expect(validation.errorFor('title'), 'Event title is required');
    });

    test('validate returns error when title exceeds 200 characters', () {
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'a' * 201,
        date: DateTime(2024, 1, 15),
      );

      final validation = formState.validate();

      expect(validation.isValid, isFalse);
      expect(validation.errorFor('title'),
          'Event title must be 200 characters or less');
    });

    test('validate returns error when date is missing', () {
      const formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Title',
      );

      final validation = formState.validate();

      expect(validation.isValid, isFalse);
      expect(validation.errorFor('date'), 'Event date is required');
    });

    test('validate returns error when date is too far in the future', () {
      final now = DateTime.now();
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Title',
        date: DateTime(now.year + 2, 1, 1),
      );

      final validation = formState.validate();

      expect(validation.isValid, isFalse);
      expect(validation.errorFor('date'),
          'Event date cannot be more than 1 year in the future');
    });

    test('validate returns error when date is too far in the past', () {
      final now = DateTime.now();
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Title',
        date: DateTime(now.year - 101, 1, 1),
      );

      final validation = formState.validate();

      expect(validation.isValid, isFalse);
      expect(validation.errorFor('date'),
          'Event date cannot be more than 100 years in the past');
    });

    test('validate returns error when description exceeds 5000 characters', () {
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Title',
        date: DateTime(2024, 1, 15),
        description: 'a' * 5001,
      );

      final validation = formState.validate();

      expect(validation.isValid, isFalse);
      expect(validation.errorFor('description'),
          'Description must be 5000 characters or less');
    });

    test('validate returns error when reminder date is before event date', () {
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Title',
        date: DateTime(2024, 2, 1),
        nextReminderDate: DateTime(2024, 1, 1),
      );

      final validation = formState.validate();

      expect(validation.isValid, isFalse);
      expect(validation.errorFor('nextReminderDate'),
          'Reminder date cannot be before event date');
    });

    test('validate returns error when reminder date is too far in the future',
        () {
      final now = DateTime.now();
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Title',
        date: now,
        nextReminderDate: DateTime(now.year + 3, 1, 1),
      );

      final validation = formState.validate();

      expect(validation.isValid, isFalse);
      expect(validation.errorFor('nextReminderDate'),
          'Reminder date cannot be more than 2 years in the future');
    });

    test('validate returns error when attachment is invalid URL', () {
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Title',
        date: DateTime(2024, 1, 15),
        attachments: ['not-a-url'],
      );

      final validation = formState.validate();

      expect(validation.isValid, isFalse);
      expect(validation.errorFor('attachments'),
          'All attachments must be valid HTTP/HTTPS URLs');
    });

    test('validate accepts valid HTTP URL in attachments', () {
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Title',
        date: DateTime(2024, 1, 15),
        attachments: ['http://example.com/doc.pdf'],
      );

      final validation = formState.validate();

      expect(validation.isValid, isTrue);
    });

    test('validate accepts valid HTTPS URL in attachments', () {
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Title',
        date: DateTime(2024, 1, 15),
        attachments: ['https://example.com/doc.pdf'],
      );

      final validation = formState.validate();

      expect(validation.isValid, isTrue);
    });

    test('validate allows multiple validation errors', () {
      const formState = PetEventFormState(
        title: '',
        date: null,
      );

      final validation = formState.validate();

      expect(validation.isValid, isFalse);
      expect(validation.errors.length, greaterThan(1));
      expect(validation.errorFor('type'), isNotNull);
      expect(validation.errorFor('title'), isNotNull);
      expect(validation.errorFor('date'), isNotNull);
    });

    test('toEvent converts valid form state to event entity', () {
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Annual vaccination',
        description: 'Rabies shot',
        date: DateTime(2024, 1, 15),
        nextReminderDate: DateTime(2025, 1, 15),
        attachments: ['https://example.com/cert.pdf'],
      );

      final event = formState.toEvent(
        id: const EntityId('event-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 15),
      );

      expect(event.id, const EntityId('event-1'));
      expect(event.userId, const EntityId('user-1'));
      expect(event.petId, const EntityId('pet-1'));
      expect(event.type, PetEventType.vaccination);
      expect(event.title, 'Annual vaccination');
      expect(event.description, 'Rabies shot');
      expect(event.date.value.toUtc(), DateTime(2024, 1, 15).toUtc());
      expect(
          event.nextReminderDate?.value.toUtc(), DateTime(2025, 1, 15).toUtc());
      expect(event.attachments.length, 1);
      expect(
          event.attachments.first.toString(), 'https://example.com/cert.pdf');
      expect(event.source, PetEventSource.manual);
      expect(event.createdAt?.value.toUtc(), DateTime(2024, 1, 1).toUtc());
      expect(event.updatedAt?.value.toUtc(), DateTime(2024, 1, 15).toUtc());
    });

    test('toEvent trims whitespace from string fields', () {
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: '  Title  ',
        description: '  Description  ',
        date: DateTime(2024, 1, 15),
      );

      final event = formState.toEvent(
        id: const EntityId('event-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
      );

      expect(event.title, 'Title');
      expect(event.description, 'Description');
    });

    test('toEvent converts empty optional description to null', () {
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Title',
        description: '   ',
        date: DateTime(2024, 1, 15),
      );

      final event = formState.toEvent(
        id: const EntityId('event-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
      );

      expect(event.description, isNull);
    });

    test('toEvent filters out empty attachment strings', () {
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Title',
        date: DateTime(2024, 1, 15),
        attachments: [
          'https://example.com/doc1.pdf',
          '',
          '   ',
          'https://example.com/doc2.pdf',
        ],
      );

      final event = formState.toEvent(
        id: const EntityId('event-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
      );

      expect(event.attachments.length, 2);
      expect(event.attachments[0].toString(), 'https://example.com/doc1.pdf');
      expect(event.attachments[1].toString(), 'https://example.com/doc2.pdf');
    });

    test('toEvent throws PetEventFormValidationException when form is invalid',
        () {
      const formState = PetEventFormState(
        title: '',
        date: null,
      );

      expect(
        () => formState.toEvent(
          id: const EntityId('event-1'),
          userId: const EntityId('user-1'),
          petId: const EntityId('pet-1'),
        ),
        throwsA(isA<PetEventFormValidationException>()),
      );
    });

    test('toEvent includes timestamps when provided', () {
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Title',
        date: DateTime(2024, 1, 15),
      );

      final event = formState.toEvent(
        id: const EntityId('event-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 10),
      );

      expect(event.createdAt?.value.toUtc(), DateTime(2024, 1, 1).toUtc());
      expect(event.updatedAt?.value.toUtc(), DateTime(2024, 1, 10).toUtc());
    });

    test('toEvent omits timestamps when not provided', () {
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Title',
        date: DateTime(2024, 1, 15),
      );

      final event = formState.toEvent(
        id: const EntityId('event-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
      );

      expect(event.createdAt, isNull);
      expect(event.updatedAt, isNull);
    });
  });
}
