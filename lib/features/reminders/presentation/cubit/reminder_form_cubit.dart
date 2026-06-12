import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/reminders/domain/services/reminder_notification_scheduler.dart';
import 'package:paw_vault/features/reminders/presentation/models/reminder_form_state.dart';

class ReminderFormCubit extends Cubit<ReminderFormCubitState> {
  ReminderFormCubit({
    required ReminderRepository reminderRepository,
    required AuthRepository authRepository,
    required ReminderNotificationScheduler notificationScheduler,
  })  : _reminderRepository = reminderRepository,
        _authRepository = authRepository,
        _notificationScheduler = notificationScheduler,
        super(const ReminderFormCubitState());

  final ReminderRepository _reminderRepository;
  final AuthRepository _authRepository;
  final ReminderNotificationScheduler _notificationScheduler;

  Future<void> load(String petId, String reminderId) async {
    emit(ReminderFormCubitState(
      status: ReminderFormStatus.loading,
      petId: petId,
      reminderId: reminderId,
    ));

    try {
      await _reminderRepository.initialize();
      final user = await _authRepository.currentUser() ??
          await _authRepository.signInAnonymously();
      final userId = EntityId(user.id);
      final reminder = await _reminderRepository.getReminder(
        userId: userId,
        petId: EntityId(petId),
        reminderId: EntityId(reminderId),
      );

      emit(
        ReminderFormCubitState(
          status: reminder == null
              ? ReminderFormStatus.notFound
              : ReminderFormStatus.ready,
          userId: userId,
          petId: petId,
          reminderId: reminderId,
          reminder: reminder,
        ),
      );
    } catch (error) {
      emit(
        ReminderFormCubitState(
          status: ReminderFormStatus.failure,
          petId: petId,
          reminderId: reminderId,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> createReminder(
    String petId,
    ReminderFormState formState,
  ) async {
    if (!formState.validate().isValid) {
      emit(
        state.copyWith(
          status: ReminderFormStatus.failure,
          errorMessage: 'Please fix validation errors',
        ),
      );
      return;
    }

    emit(state.copyWith(status: ReminderFormStatus.saving));

    try {
      await _reminderRepository.initialize();
      final user = await _authRepository.currentUser() ??
          await _authRepository.signInAnonymously();
      final userId = EntityId(user.id);
      final entityPetId = EntityId(petId);
      final now = DateTime.now();
      final reminderId = EntityId('${now.microsecondsSinceEpoch}');

      final reminder = formState.toReminder(
        id: reminderId,
        userId: userId,
        petId: entityPetId,
        createdAt: now,
        updatedAt: now,
      );

      await _reminderRepository.saveReminder(reminder);
      await _scheduleQuietly(reminder);

      emit(
        ReminderFormCubitState(
          status: ReminderFormStatus.ready,
          userId: userId,
          petId: petId,
          reminderId: reminderId.value,
          reminder: reminder,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ReminderFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> updateReminder(ReminderFormState formState) async {
    final current = state.reminder;
    if (current == null) {
      emit(
        state.copyWith(
          status: ReminderFormStatus.failure,
          errorMessage: 'Cannot update: no reminder loaded',
        ),
      );
      return;
    }

    if (!formState.validate().isValid) {
      emit(
        state.copyWith(
          status: ReminderFormStatus.failure,
          errorMessage: 'Please fix validation errors',
        ),
      );
      return;
    }

    emit(state.copyWith(status: ReminderFormStatus.saving));

    try {
      await _reminderRepository.initialize();
      final now = DateTime.now();

      final updated = formState.toReminder(
        id: current.id,
        userId: current.userId,
        petId: current.petId,
        isCompleted: current.isCompleted,
        relatedEventId: current.relatedEventId,
        createdAt: current.createdAt?.value,
        updatedAt: now,
      );

      await _reminderRepository.saveReminder(updated);
      await _scheduleQuietly(updated);

      emit(
        state.copyWith(
          status: ReminderFormStatus.ready,
          reminder: updated,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ReminderFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> completeReminder() async {
    final current = state.reminder;
    if (current == null) {
      emit(
        state.copyWith(
          status: ReminderFormStatus.failure,
          errorMessage: 'Cannot complete: no reminder loaded',
        ),
      );
      return;
    }

    emit(state.copyWith(status: ReminderFormStatus.saving));

    try {
      await _reminderRepository.initialize();
      await _reminderRepository.completeReminder(
        userId: current.userId,
        petId: current.petId,
        reminderId: current.id,
      );
      await _cancelQuietly(current.id);

      emit(
        state.copyWith(
          status: ReminderFormStatus.ready,
          reminder: _completed(current),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ReminderFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> deleteReminder() async {
    final current = state.reminder;
    if (current == null) {
      emit(
        state.copyWith(
          status: ReminderFormStatus.failure,
          errorMessage: 'Cannot delete: no reminder loaded',
        ),
      );
      return;
    }

    emit(state.copyWith(status: ReminderFormStatus.deleting));

    try {
      await _reminderRepository.initialize();
      await _reminderRepository.deleteReminder(
        userId: current.userId,
        petId: current.petId,
        reminderId: current.id,
      );
      await _cancelQuietly(current.id);

      emit(
        ReminderFormCubitState(
          status: ReminderFormStatus.ready,
          userId: state.userId,
          petId: state.petId,
          reminderId: state.reminderId,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ReminderFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Scheduling notifications is best-effort: a failure here must not fail the
  /// save the user just performed.
  Future<void> _scheduleQuietly(Reminder reminder) async {
    try {
      await _notificationScheduler.schedule(reminder);
    } catch (_) {
      // Ignore notification scheduling errors.
    }
  }

  Future<void> _cancelQuietly(EntityId reminderId) async {
    try {
      await _notificationScheduler.cancel(reminderId);
    } catch (_) {
      // Ignore notification cancellation errors.
    }
  }

  Reminder _completed(Reminder reminder) {
    return Reminder(
      id: reminder.id,
      userId: reminder.userId,
      petId: reminder.petId,
      title: reminder.title,
      description: reminder.description,
      dateTime: reminder.dateTime,
      repeatType: reminder.repeatType,
      relatedEventId: reminder.relatedEventId,
      isCompleted: true,
      createdAt: reminder.createdAt,
      updatedAt: reminder.updatedAt,
    );
  }
}

enum ReminderFormStatus {
  initial,
  loading,
  ready,
  saving,
  deleting,
  notFound,
  failure,
}

class ReminderFormCubitState {
  const ReminderFormCubitState({
    this.status = ReminderFormStatus.initial,
    this.userId,
    this.petId,
    this.reminderId,
    this.reminder,
    this.errorMessage,
  });

  final ReminderFormStatus status;
  final EntityId? userId;
  final String? petId;
  final String? reminderId;
  final Reminder? reminder;
  final String? errorMessage;

  bool get isReady => status == ReminderFormStatus.ready;

  ReminderFormCubitState copyWith({
    ReminderFormStatus? status,
    EntityId? userId,
    String? petId,
    String? reminderId,
    Reminder? reminder,
    String? errorMessage,
  }) {
    return ReminderFormCubitState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      reminderId: reminderId ?? this.reminderId,
      reminder: reminder ?? this.reminder,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
