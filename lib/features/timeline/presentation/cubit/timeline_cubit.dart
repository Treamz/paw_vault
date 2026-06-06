import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';

class TimelineCubit extends Cubit<TimelineState> {
  TimelineCubit(this._timelineRepository) : super(const TimelineState());

  final TimelineRepository _timelineRepository;

  Future<void> load(String petId) async {
    await _timelineRepository.initialize();
    emit(TimelineState(petId: petId, isReady: true));
  }
}

class TimelineState {
  const TimelineState({
    this.petId,
    this.isReady = false,
  });

  final String? petId;
  final bool isReady;
}
