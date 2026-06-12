import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';

class RemindersCubit extends Cubit<RemindersState> {
  RemindersCubit({
    required ReminderRepository reminderRepository,
    required AuthRepository authRepository,
  })  : _reminderRepository = reminderRepository,
        _authRepository = authRepository,
        super(const RemindersState());

  final ReminderRepository _reminderRepository;
  final AuthRepository _authRepository;
  StreamSubscription<List<Reminder>>? _remindersSubscription;

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
