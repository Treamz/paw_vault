import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/reminders/domain/services/reminder_notification_scheduler.dart';

class RemindersCubit extends Cubit<RemindersState> {
  RemindersCubit({
    required ReminderRepository reminderRepository,
    required AuthRepository authRepository,
    required ReminderNotificationScheduler notificationScheduler,
  })  : _reminderRepository = reminderRepository,
        _authRepository = authRepository,
        _notificationScheduler = notificationScheduler,
        super(const RemindersState());

  final ReminderRepository _reminderRepository;
  final AuthRepository _authRepository;
  final ReminderNotificationScheduler _notificationScheduler;
  StreamSubscription<List<Reminder>>? _remindersSubscription;

  /// Toggles a reminder's completed flag from the list. Completing cancels
  /// its notification; un-completing restores it (future dues only).
  Future<void> toggleCompleted(Reminder reminder) async {
    try {
      if (reminder.isCompleted) {
        final reopened = Reminder(
          id: reminder.id,
          userId: reminder.userId,
          petId: reminder.petId,
          title: reminder.title,
          description: reminder.description,
          dateTime: reminder.dateTime,
          repeatType: reminder.repeatType,
          relatedEventId: reminder.relatedEventId,
          createdAt: reminder.createdAt,
        );
        await _reminderRepository.saveReminder(reopened);
        await _notificationScheduler.schedule(reopened);
      } else {
        await _reminderRepository.completeReminder(
          userId: reminder.userId,
          petId: reminder.petId,
          reminderId: reminder.id,
        );
        await _notificationScheduler.cancel(reminder.id);
      }
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  Future<void> load(String petId) async {
    emit(RemindersState(status: RemindersStatus.loading, petId: petId));

    try {
      await _reminderRepository.initialize();
      final user = await _authRepository.currentUser() ??
          await _authRepository.signInAnonymously();
      final userId = EntityId(user.id);
      final entityPetId = EntityId(petId);

      await _remindersSubscription?.cancel();
      _remindersSubscription = _reminderRepository
          .watchReminders(userId: userId, petId: entityPetId)
          .listen(
        (reminders) {
          emit(
            RemindersState(
              status: RemindersStatus.ready,
              userId: userId,
              petId: petId,
              reminders: reminders,
            ),
          );
        },
        onError: (Object error) {
          emit(
            RemindersState(
              status: RemindersStatus.failure,
              userId: userId,
              petId: petId,
              errorMessage: error.toString(),
            ),
          );
        },
      );
    } catch (error) {
      emit(
        RemindersState(
          status: RemindersStatus.failure,
          petId: petId,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _remindersSubscription?.cancel();
    return super.close();
  }
}

enum RemindersStatus {
  initial,
  loading,
  ready,
  failure,
}

class RemindersState {
  const RemindersState({
    this.status = RemindersStatus.initial,
    this.userId,
    this.petId,
    this.reminders = const [],
    this.errorMessage,
  });

  final RemindersStatus status;
  final EntityId? userId;
  final String? petId;
  final List<Reminder> reminders;
  final String? errorMessage;

  bool get isReady => status == RemindersStatus.ready;

  RemindersState copyWith({
    RemindersStatus? status,
    EntityId? userId,
    String? petId,
    List<Reminder>? reminders,
    String? errorMessage,
  }) {
    return RemindersState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      reminders: reminders ?? this.reminders,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Reminders sorted by due date, with pending ones before completed ones.
  List<Reminder> get sortedReminders {
    final sorted = [...reminders];
    sorted.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return a.dateTime.value.compareTo(b.dateTime.value);
    });
    return sorted;
  }
}
