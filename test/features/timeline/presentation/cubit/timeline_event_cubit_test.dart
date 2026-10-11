import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/reminders/domain/services/reminder_notification_scheduler.dart';
import 'package:paw_vault/features/timeline/application/event_attachment_upload_service.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/timeline/domain/services/event_photo_picker.dart';
import 'package:paw_vault/features/timeline/presentation/cubit/timeline_event_cubit.dart';
import 'package:paw_vault/features/timeline/presentation/models/pet_event_form_state.dart';

void main() {
  group('TimelineEventCubit', () {
    test('loads the current user and fetches the requested event', () async {
      final event = _event();
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository(event: event);
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: _FakeReminderRepository(),
        notificationScheduler: _FakeNotificationScheduler(),
      );
      final states = <TimelineEventState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.load('pet-1', 'event-1');
      await Future<void>.delayed(Duration.zero);

      expect(timelineRepository.initializeCallCount, 1);
      expect(authRepository.currentUserCallCount, 1);
      expect(authRepository.signInAnonymouslyCallCount, isZero);
      expect(timelineRepository.requestedUserId, const EntityId('user-1'));
      expect(timelineRepository.requestedPetId, const EntityId('pet-1'));
      expect(timelineRepository.requestedEventId, const EntityId('event-1'));
      expect(states.first.status, TimelineEventStatus.loading);
      expect(states.last.status, TimelineEventStatus.ready);
      expect(states.last.userId, const EntityId('user-1'));
      expect(states.last.petId, 'pet-1');
      expect(states.last.eventId, 'event-1');
      expect(states.last.event, event);
      expect(states.last.isReady, isTrue);

      await subscription.cancel();
      await cubit.close();
    });

    test('signs in anonymously when no current user exists', () async {
      final event = _event(userId: const EntityId('anonymous-user'));
      final authRepository = _FakeAuthRepository(
        signedInUser: const AppUser(id: 'anonymous-user', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository(event: event);
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: _FakeReminderRepository(),
        notificationScheduler: _FakeNotificationScheduler(),
      );

      await cubit.load('pet-1', 'event-1');

      expect(authRepository.currentUserCallCount, 1);
      expect(authRepository.signInAnonymouslyCallCount, 1);
      expect(
        timelineRepository.requestedUserId,
        const EntityId('anonymous-user'),
      );
      expect(cubit.state.status, TimelineEventStatus.ready);

      await cubit.close();
    });

    test('emits notFound when repository returns no event', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository();
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: _FakeReminderRepository(),
        notificationScheduler: _FakeNotificationScheduler(),
      );

      await cubit.load('pet-1', 'missing-event');

      expect(cubit.state.status, TimelineEventStatus.notFound);
      expect(cubit.state.userId, const EntityId('user-1'));
      expect(cubit.state.petId, 'pet-1');
      expect(cubit.state.eventId, 'missing-event');
      expect(cubit.state.event, isNull);
      expect(cubit.state.isReady, isFalse);

      await cubit.close();
    });

    test('emits failure when loading throws', () async {
      final authRepository = _FakeAuthRepository();
      final timelineRepository =
          _FakeTimelineRepository(throwsOnInitialize: true);
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: _FakeReminderRepository(),
        notificationScheduler: _FakeNotificationScheduler(),
      );

      await cubit.load('pet-1', 'event-1');

      expect(cubit.state.status, TimelineEventStatus.failure);
      expect(cubit.state.petId, 'pet-1');
      expect(cubit.state.eventId, 'event-1');
      expect(cubit.state.errorMessage, contains('initialize failed'));

      await cubit.close();
    });

    test('creates a new event from form state', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository();
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: _FakeReminderRepository(),
        notificationScheduler: _FakeNotificationScheduler(),
      );
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Annual vaccination',
        date: DateTime(2024, 1, 15),
        description: 'Rabies shot',
      );
      final states = <TimelineEventState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.createEvent('pet-1', formState);
      await Future<void>.delayed(Duration.zero);

      expect(timelineRepository.initializeCallCount, 1);
      expect(timelineRepository.saveEventCallCount, 1);
      expect(timelineRepository.savedEvent, isNotNull);
      expect(timelineRepository.savedEvent!.type, PetEventType.vaccination);
      expect(timelineRepository.savedEvent!.title, 'Annual vaccination');
      expect(timelineRepository.savedEvent!.description, 'Rabies shot');
      expect(timelineRepository.savedEvent!.userId, const EntityId('user-1'));
      expect(timelineRepository.savedEvent!.petId, const EntityId('pet-1'));
      expect(states.first.status, TimelineEventStatus.saving);
      expect(states.last.status, TimelineEventStatus.ready);
      expect(states.last.event, timelineRepository.savedEvent);
      expect(states.last.userId, const EntityId('user-1'));
      expect(states.last.petId, 'pet-1');
      expect(states.last.eventId, isNotEmpty);

      await subscription.cancel();
      await cubit.close();
    });

    test('creates event with anonymous user when no current user', () async {
      final authRepository = _FakeAuthRepository(
        signedInUser: const AppUser(id: 'anon-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository();
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: _FakeReminderRepository(),
        notificationScheduler: _FakeNotificationScheduler(),
      );
      final formState = PetEventFormState(
        type: PetEventType.vetVisit,
        title: 'Vet checkup',
        date: DateTime(2024, 1, 15),
      );

      await cubit.createEvent('pet-1', formState);

      expect(authRepository.signInAnonymouslyCallCount, 1);
      expect(timelineRepository.savedEvent!.userId, const EntityId('anon-1'));
      expect(cubit.state.status, TimelineEventStatus.ready);

      await cubit.close();
    });

    test('emits failure when create throws', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository(throwsOnSave: true);
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: _FakeReminderRepository(),
        notificationScheduler: _FakeNotificationScheduler(),
      );
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Vaccination',
        date: DateTime(2024, 1, 15),
      );

      await cubit.createEvent('pet-1', formState);

      expect(cubit.state.status, TimelineEventStatus.failure);
      expect(cubit.state.errorMessage, contains('save failed'));

      await cubit.close();
    });

    test('updates an existing event from form state', () async {
      final existingEvent = PetEvent(
        id: const EntityId('event-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        type: PetEventType.vaccination,
        title: 'Old title',
        date: UtcDateTime(DateTime(2024, 1, 15)),
        source: PetEventSource.manual,
      );
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository(event: existingEvent);
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: _FakeReminderRepository(),
        notificationScheduler: _FakeNotificationScheduler(),
      );

      await cubit.load('pet-1', 'event-1');

      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Updated title',
        date: DateTime(2024, 1, 15),
        description: 'New description',
      );
      final states = <TimelineEventState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.updateEvent(formState);
      await Future<void>.delayed(Duration.zero);

      expect(timelineRepository.saveEventCallCount, 1);
      expect(timelineRepository.savedEvent, isNotNull);
      expect(timelineRepository.savedEvent!.id, const EntityId('event-1'));
      expect(timelineRepository.savedEvent!.userId, const EntityId('user-1'));
      expect(timelineRepository.savedEvent!.petId, const EntityId('pet-1'));
      expect(timelineRepository.savedEvent!.title, 'Updated title');
      expect(timelineRepository.savedEvent!.description, 'New description');
      expect(states.first.status, TimelineEventStatus.saving);
      expect(states.last.status, TimelineEventStatus.ready);
      expect(states.last.event!.title, 'Updated title');

      await subscription.cancel();
      await cubit.close();
    });

    test('emits failure when updating with no loaded event', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository();
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: _FakeReminderRepository(),
        notificationScheduler: _FakeNotificationScheduler(),
      );
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Title',
        date: DateTime(2024, 1, 15),
      );

      await cubit.updateEvent(formState);

      expect(cubit.state.status, TimelineEventStatus.failure);
      expect(
        cubit.state.errorMessage,
        contains('Cannot update: no event loaded'),
      );
      expect(timelineRepository.saveEventCallCount, isZero);

      await cubit.close();
    });

    test('emits failure when update throws', () async {
      final existingEvent = PetEvent(
        id: const EntityId('event-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        type: PetEventType.vaccination,
        title: 'Old title',
        date: UtcDateTime(DateTime(2024, 1, 15)),
        source: PetEventSource.manual,
      );
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository(
        event: existingEvent,
        throwsOnSave: true,
      );
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: _FakeReminderRepository(),
        notificationScheduler: _FakeNotificationScheduler(),
      );

      await cubit.load('pet-1', 'event-1');

      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Updated title',
        date: DateTime(2024, 1, 15),
      );

      await cubit.updateEvent(formState);

      expect(cubit.state.status, TimelineEventStatus.failure);
      expect(cubit.state.errorMessage, contains('save failed'));

      await cubit.close();
    });

    test('deletes an existing event', () async {
      final existingEvent = PetEvent(
        id: const EntityId('event-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        type: PetEventType.vaccination,
        title: 'Event to delete',
        date: UtcDateTime(DateTime(2024, 1, 15)),
        source: PetEventSource.manual,
      );
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository(event: existingEvent);
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: _FakeReminderRepository(),
        notificationScheduler: _FakeNotificationScheduler(),
      );

      await cubit.load('pet-1', 'event-1');

      final states = <TimelineEventState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.deleteEvent();
      await Future<void>.delayed(Duration.zero);

      expect(timelineRepository.deleteEventCallCount, 1);
      expect(timelineRepository.deletedUserId, const EntityId('user-1'));
      expect(timelineRepository.deletedPetId, const EntityId('pet-1'));
      expect(timelineRepository.deletedEventId, const EntityId('event-1'));
      expect(states.first.status, TimelineEventStatus.deleting);
      expect(states.last.status, TimelineEventStatus.ready);
      expect(states.last.event, isNull);

      await subscription.cancel();
      await cubit.close();
    });

    test('an event with a reminder date gets a scheduled reminder', () async {
      // The field used to be rendered on the timeline and nowhere else:
      // nothing scheduled a notification, so "Reminder" never reminded.
      final reminders = _FakeReminderRepository();
      final scheduler = _FakeNotificationScheduler();
      final timelineRepository = _FakeTimelineRepository();
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: _FakeAuthRepository(
          currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
        ),
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: reminders,
        notificationScheduler: scheduler,
      );

      await cubit.createEvent(
        'pet-1',
        PetEventFormState(
          type: PetEventType.vaccination,
          title: 'Booster due',
          date: DateTime(2026, 10, 7),
          description: 'Second dose',
          nextReminderDate: DateTime(2026, 11, 7, 9),
        ),
      );

      final reminder = reminders.saved.single;
      expect(reminder.title, 'Booster due');
      expect(reminder.dateTime.value, DateTime(2026, 11, 7, 9).toUtc());
      // Linked, so it can be found again and shows its origin.
      expect(reminder.relatedEventId, timelineRepository.savedEvent!.id);
      expect(scheduler.scheduled.single.id, reminder.id);

      await cubit.close();
    });

    test('an event with no reminder date schedules nothing', () async {
      final reminders = _FakeReminderRepository();
      final scheduler = _FakeNotificationScheduler();
      final cubit = TimelineEventCubit(
        timelineRepository: _FakeTimelineRepository(),
        authRepository: _FakeAuthRepository(
          currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
        ),
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: reminders,
        notificationScheduler: scheduler,
      );

      await cubit.createEvent(
        'pet-1',
        PetEventFormState(
          type: PetEventType.vaccination,
          title: 'Booster due',
          date: DateTime(2026, 10, 7),
        ),
      );

      expect(reminders.saved, isEmpty);
      expect(scheduler.scheduled, isEmpty);

      await cubit.close();
    });

    test('two events do not share one reminder', () async {
      // The id is derived from the event id. Getting that wrong would give
      // every event the same reminder, each overwriting the last.
      final reminders = _FakeReminderRepository();
      final cubit = TimelineEventCubit(
        timelineRepository: _FakeTimelineRepository(),
        authRepository: _FakeAuthRepository(
          currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
        ),
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: reminders,
        notificationScheduler: _FakeNotificationScheduler(),
      );

      PetEventFormState form(String title) => PetEventFormState(
            type: PetEventType.vaccination,
            title: title,
            date: DateTime(2026, 10, 7),
            nextReminderDate: DateTime(2026, 11, 7, 9),
          );

      await cubit.createEvent('pet-1', form('First'));
      await cubit.createEvent('pet-1', form('Second'));

      expect(reminders.saved, hasLength(2));
      expect(
        reminders.saved.map((r) => r.id.value).toSet(),
        hasLength(2),
        reason: 'each event owns its own reminder',
      );

      await cubit.close();
    });

    test('an event without a reminder never touches the scheduler', () async {
      // Cancelling unconditionally would reach the notification plugin on
      // every ordinary event save, which initialises it and asks the owner
      // for notification permission for no reason — and in a test it blocks
      // the save behind the system alert.
      final reminders = _FakeReminderRepository();
      final scheduler = _FakeNotificationScheduler();
      final event = _event();
      final cubit = TimelineEventCubit(
        timelineRepository: _FakeTimelineRepository(event: event),
        authRepository: _FakeAuthRepository(
          currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
        ),
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: reminders,
        notificationScheduler: scheduler,
      );
      await cubit.load('pet-1', event.id.value);

      await cubit.updateEvent(
        PetEventFormState(
          type: event.type,
          title: 'Renamed',
          date: event.date.value,
        ),
      );
      await cubit.deleteEvent();

      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.cancelled, isEmpty);
      expect(reminders.deleted, isEmpty);

      await cubit.close();
    });

    test('clearing the reminder date cancels and removes the reminder',
        () async {
      final reminders = _FakeReminderRepository();
      final scheduler = _FakeNotificationScheduler();
      final event = _event(
        nextReminderDate: UtcDateTime(DateTime.utc(2026, 11, 7, 9)),
      );
      // The event already has its reminder, as it would after being saved.
      await reminders.saveReminder(
        Reminder(
          id: TimelineEventCubit.reminderIdForEvent(event.id),
          userId: event.userId,
          petId: event.petId,
          title: event.title,
          dateTime: event.nextReminderDate!,
          relatedEventId: event.id,
        ),
      );
      final timelineRepository = _FakeTimelineRepository(event: event);
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: _FakeAuthRepository(
          currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
        ),
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: reminders,
        notificationScheduler: scheduler,
      );
      await cubit.load('pet-1', event.id.value);

      await cubit.updateEvent(
        PetEventFormState(
          type: event.type,
          title: event.title,
          date: event.date.value,
        ),
      );

      final reminderId = TimelineEventCubit.reminderIdForEvent(event.id);
      expect(scheduler.cancelled, contains(reminderId));
      expect(reminders.deleted, contains(reminderId));

      await cubit.close();
    });

    test('deleting an event takes its reminder with it', () async {
      // Otherwise the notification fires for something that no longer
      // exists.
      final reminders = _FakeReminderRepository();
      final scheduler = _FakeNotificationScheduler();
      final event = _event(
        nextReminderDate: UtcDateTime(DateTime.utc(2026, 11, 7, 9)),
      );
      await reminders.saveReminder(
        Reminder(
          id: TimelineEventCubit.reminderIdForEvent(event.id),
          userId: event.userId,
          petId: event.petId,
          title: event.title,
          dateTime: event.nextReminderDate!,
          relatedEventId: event.id,
        ),
      );
      final cubit = TimelineEventCubit(
        timelineRepository: _FakeTimelineRepository(event: event),
        authRepository: _FakeAuthRepository(
          currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
        ),
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: reminders,
        notificationScheduler: scheduler,
      );
      await cubit.load('pet-1', event.id.value);

      await cubit.deleteEvent();

      final reminderId = TimelineEventCubit.reminderIdForEvent(event.id);
      expect(scheduler.cancelled, contains(reminderId));
      expect(reminders.deleted, contains(reminderId));

      await cubit.close();
    });

    test('emits failure when deleting with no loaded event', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository();
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: _FakeReminderRepository(),
        notificationScheduler: _FakeNotificationScheduler(),
      );

      await cubit.deleteEvent();

      expect(cubit.state.status, TimelineEventStatus.failure);
      expect(
        cubit.state.errorMessage,
        contains('Cannot delete: no event loaded'),
      );
      expect(timelineRepository.deleteEventCallCount, isZero);

      await cubit.close();
    });

    test('emits failure when delete throws', () async {
      final existingEvent = PetEvent(
        id: const EntityId('event-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        type: PetEventType.vaccination,
        title: 'Event to delete',
        date: UtcDateTime(DateTime(2024, 1, 15)),
        source: PetEventSource.manual,
      );
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository(
        event: existingEvent,
        throwsOnDelete: true,
      );
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: _FakeReminderRepository(),
        notificationScheduler: _FakeNotificationScheduler(),
      );

      await cubit.load('pet-1', 'event-1');

      await cubit.deleteEvent();

      expect(cubit.state.status, TimelineEventStatus.failure);
      expect(cubit.state.errorMessage, contains('delete failed'));

      await cubit.close();
    });

    test('logs a timeline_event_added analytics event on create', () async {
      final analytics = _RecordingAnalytics();
      final cubit = TimelineEventCubit(
        timelineRepository: _FakeTimelineRepository(),
        authRepository: _FakeAuthRepository(
          currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
        ),
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
        reminderRepository: _FakeReminderRepository(),
        notificationScheduler: _FakeNotificationScheduler(),
        analytics: analytics,
      );

      await cubit.createEvent(
        'pet-1',
        PetEventFormState(
          type: PetEventType.vaccination,
          title: 'Rabies',
          date: DateTime(2024, 1, 15),
        ),
      );

      expect(analytics.events, ['timeline_event_added']);
      expect(analytics.lastParameters?['type'], 'vaccination');

      await cubit.close();
    });

    test('uploads pending photos on create and stores their URLs', () async {
      final timelineRepository = _FakeTimelineRepository();
      final storageRepository = _FakeStorageRepository();
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: _FakeAuthRepository(
          currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
        ),
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: storageRepository,
        ),
        reminderRepository: _FakeReminderRepository(),
        notificationScheduler: _FakeNotificationScheduler(),
      );

      await cubit.createEvent(
        'pet-1',
        PetEventFormState(
          type: PetEventType.vaccination,
          title: 'Vaccination',
          date: DateTime(2024, 1, 15),
          pendingPhotos: [
            PickedEventPhoto(
              bytes: Uint8List.fromList([1, 2, 3]),
              contentType: 'image/jpeg',
              extension: 'jpg',
            ),
          ],
        ),
      );

      expect(cubit.state.status, TimelineEventStatus.ready);
      expect(storageRepository.uploadCallCount, 1);
      expect(
        storageRepository.uploadedPath,
        allOf(
          startsWith('users/user-1/pets/pet-1/events/'),
          contains('/attachments/'),
          endsWith('.jpg'),
        ),
      );
      expect(storageRepository.uploadedContentType, 'image/jpeg');
      final saved = timelineRepository.savedEvent!;
      expect(saved.attachments, hasLength(1));
      expect(
        saved.attachments.single.toString(),
        'https://cdn.example.com/${storageRepository.uploadedPath}',
      );

      await cubit.close();
    });

    test('creates an event without photos and uploads nothing', () async {
      final timelineRepository = _FakeTimelineRepository();
      final storageRepository = _FakeStorageRepository();
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: _FakeAuthRepository(
          currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
        ),
        attachmentUploadService: EventAttachmentUploadService(
          storageRepository: storageRepository,
        ),
        reminderRepository: _FakeReminderRepository(),
        notificationScheduler: _FakeNotificationScheduler(),
      );

      await cubit.createEvent(
        'pet-1',
        PetEventFormState(
          type: PetEventType.vaccination,
          title: 'Vaccination',
          date: DateTime(2024, 1, 15),
        ),
      );

      expect(storageRepository.uploadCallCount, isZero);
      expect(timelineRepository.savedEvent!.attachments, isEmpty);

      await cubit.close();
    });
  });
}

class _FakeStorageRepository implements StorageRepository {
  int uploadCallCount = 0;
  String? uploadedPath;
  String? uploadedContentType;

  @override
  Future<void> delete(String path) async {}

  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadCallCount++;
    uploadedPath = path;
    uploadedContentType = contentType;
    return StorageFile(
      path: path,
      downloadUrl: Uri.parse('https://cdn.example.com/$path'),
    );
  }
}

class _RecordingAnalytics implements AnalyticsService {
  final List<String> events = [];
  Map<String, Object?>? lastParameters;

  @override
  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {
    events.add(name);
    lastParameters = parameters;
  }

  @override
  Future<void> logScreenView(String screenName) async {}

  @override
  Future<void> setUserId(String? userId) async {}
}

PetEvent _event({
  EntityId userId = const EntityId('user-1'),
  UtcDateTime? nextReminderDate,
}) {
  return PetEvent(
    id: const EntityId('event-1'),
    userId: userId,
    petId: const EntityId('pet-1'),
    type: PetEventType.vaccination,
    title: 'Annual vaccination',
    date: UtcDateTime(DateTime(2024, 1, 15)),
    nextReminderDate: nextReminderDate,
    source: PetEventSource.manual,
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.currentUserValue,
    this.signedInUser = const AppUser(id: 'signed-in-user', isAnonymous: true),
  });

  final AppUser? currentUserValue;
  final AppUser signedInUser;

  int currentUserCallCount = 0;
  int signInAnonymouslyCallCount = 0;

  @override
  Future<AppUser?> currentUser() async {
    currentUserCallCount++;
    return currentUserValue;
  }

  @override
  Future<AppUser> signInAnonymously() async {
    signInAnonymouslyCallCount++;
    return signedInUser;
  }

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() {
    return Stream<AppUser?>.value(currentUserValue);
  }
}

class _FakeTimelineRepository implements TimelineRepository {
  _FakeTimelineRepository({
    this.event,
    this.throwsOnInitialize = false,
    this.throwsOnSave = false,
    this.throwsOnDelete = false,
  });

  final PetEvent? event;
  final bool throwsOnInitialize;
  final bool throwsOnSave;
  final bool throwsOnDelete;

  int initializeCallCount = 0;
  int saveEventCallCount = 0;
  int deleteEventCallCount = 0;
  EntityId? requestedUserId;
  EntityId? requestedPetId;
  EntityId? requestedEventId;
  EntityId? deletedUserId;
  EntityId? deletedPetId;
  EntityId? deletedEventId;
  PetEvent? savedEvent;

  @override
  Future<void> deleteEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async {
    deleteEventCallCount++;
    deletedUserId = userId;
    deletedPetId = petId;
    deletedEventId = eventId;
    if (throwsOnDelete) {
      throw StateError('delete failed');
    }
  }

  @override
  Future<PetEvent?> getEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async {
    requestedUserId = userId;
    requestedPetId = petId;
    requestedEventId = eventId;
    return event;
  }

  @override
  Future<void> initialize() async {
    initializeCallCount++;
    if (throwsOnInitialize) {
      throw StateError('initialize failed');
    }
  }

  @override
  Future<void> saveEvent(PetEvent event) async {
    saveEventCallCount++;
    if (throwsOnSave) {
      throw StateError('save failed');
    }
    savedEvent = event;
  }

  @override
  Stream<List<PetEvent>> watchEvents({
    required EntityId userId,
    required EntityId petId,
  }) {
    return Stream<List<PetEvent>>.value(const []);
  }
}

/// Records what the event's linked reminder does, so a test can see whether
/// saving an event with a reminder date actually produces one.
class _FakeReminderRepository implements ReminderRepository {
  final saved = <Reminder>[];
  final deleted = <EntityId>[];

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<Reminder>> watchReminders({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream<List<Reminder>>.value(List.of(saved));

  @override
  Future<Reminder?> getReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async {
    for (final reminder in saved) {
      if (reminder.id == reminderId) {
        return reminder;
      }
    }
    return null;
  }

  @override
  Future<void> saveReminder(Reminder reminder) async {
    saved.removeWhere((existing) => existing.id == reminder.id);
    saved.add(reminder);
  }

  @override
  Future<void> completeReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async {}

  @override
  Future<void> deleteReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async {
    deleted.add(reminderId);
    saved.removeWhere((existing) => existing.id == reminderId);
  }
}

class _FakeNotificationScheduler implements ReminderNotificationScheduler {
  final scheduled = <Reminder>[];
  final cancelled = <EntityId>[];

  @override
  Stream<ReminderNotificationTap> get taps =>
      const Stream<ReminderNotificationTap>.empty();

  @override
  Future<void> schedule(Reminder reminder) async => scheduled.add(reminder);

  @override
  Future<void> cancel(EntityId reminderId) async => cancelled.add(reminderId);
}
