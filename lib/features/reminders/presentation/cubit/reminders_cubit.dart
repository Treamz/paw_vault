import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';

class RemindersCubit extends Cubit<RemindersState> {
  RemindersCubit(this._reminderRepository) : super(const RemindersState());

  final ReminderRepository _reminderRepository;

  Future<void> load(String petId) async {
    await _reminderRepository.initialize();
    emit(RemindersState(petId: petId, isReady: true));
  }
}

class RemindersState {
  const RemindersState({
    this.petId,
    this.isReady = false,
  });

  final String? petId;
  final bool isReady;
}
