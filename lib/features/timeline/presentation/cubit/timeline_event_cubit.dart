import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/analytics/data/services/noop_analytics_service.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_events.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/timeline/presentation/models/pet_event_form_state.dart';

class TimelineEventCubit extends Cubit<TimelineEventState> {
  TimelineEventCubit({
    required TimelineRepository timelineRepository,
    required AuthRepository authRepository,
    AnalyticsService? analytics,
  })  : _timelineRepository = timelineRepository,
        _authRepository = authRepository,
        _analytics = analytics ?? const NoopAnalyticsService(),
        super(const TimelineEventState());

  final TimelineRepository _timelineRepository;
  final AuthRepository _authRepository;
  final AnalyticsService _analytics;

  Future<void> load(String petId, String eventId) async {
    emit(
      TimelineEventState(
        status: TimelineEventStatus.loading,
        petId: petId,
        eventId: eventId,
      ),
    );

    try {
      await _timelineRepository.initialize();
      final user = await _authRepository.currentUser() ??
          await _authRepository.signInAnonymously();
      final userId = EntityId(user.id);
      final entityPetId = EntityId(petId);
      final entityEventId = EntityId(eventId);
      final event = await _timelineRepository.getEvent(
        userId: userId,
        petId: entityPetId,
        eventId: entityEventId,
      );

      emit(
        TimelineEventState(
          status: event == null
              ? TimelineEventStatus.notFound
              : TimelineEventStatus.ready,
          userId: userId,
          petId: petId,
          eventId: eventId,
          event: event,
        ),
      );
    } catch (error) {
      emit(
        TimelineEventState(
          status: TimelineEventStatus.failure,
          petId: petId,
          eventId: eventId,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> createEvent(String petId, PetEventFormState formState) async {
    emit(state.copyWith(status: TimelineEventStatus.saving));

    try {
      await _timelineRepository.initialize();
      final user = await _authRepository.currentUser() ??
          await _authRepository.signInAnonymously();
      final userId = EntityId(user.id);
      final entityPetId = EntityId(petId);
      final now = DateTime.now();
      final eventId = EntityId('${now.microsecondsSinceEpoch}');

      final event = formState.toEvent(
        id: eventId,
        userId: userId,
        petId: entityPetId,
        createdAt: now,
        updatedAt: now,
      );

      await _timelineRepository.saveEvent(event);
      _analytics.logEvent(
        AnalyticsEvents.timelineEventAdded,
        parameters: {AnalyticsParams.type: event.type.name},
      );

      emit(
        TimelineEventState(
          status: TimelineEventStatus.ready,
          userId: userId,
          petId: petId,
          eventId: eventId.value,
          event: event,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TimelineEventStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> updateEvent(PetEventFormState formState) async {
    final currentEvent = state.event;
    if (currentEvent == null) {
      emit(
        state.copyWith(
          status: TimelineEventStatus.failure,
          errorMessage: 'Cannot update: no event loaded',
        ),
      );
      return;
    }

    emit(state.copyWith(status: TimelineEventStatus.saving));

    try {
      await _timelineRepository.initialize();
      final now = DateTime.now();

      final updatedEvent = formState.toEvent(
        id: currentEvent.id,
        userId: currentEvent.userId,
        petId: currentEvent.petId,
        createdAt: currentEvent.createdAt?.value,
        updatedAt: now,
      );

      await _timelineRepository.saveEvent(updatedEvent);

      emit(
        state.copyWith(
          status: TimelineEventStatus.ready,
          event: updatedEvent,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TimelineEventStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> deleteEvent() async {
    final currentEvent = state.event;
    if (currentEvent == null) {
      emit(
        state.copyWith(
          status: TimelineEventStatus.failure,
          errorMessage: 'Cannot delete: no event loaded',
        ),
      );
      return;
    }

    emit(state.copyWith(status: TimelineEventStatus.deleting));

    try {
      await _timelineRepository.initialize();
      await _timelineRepository.deleteEvent(
        userId: currentEvent.userId,
        petId: currentEvent.petId,
        eventId: currentEvent.id,
      );

      emit(
        TimelineEventState(
          status: TimelineEventStatus.ready,
          userId: state.userId,
          petId: state.petId,
          eventId: state.eventId,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TimelineEventStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}

enum TimelineEventStatus {
  initial,
  loading,
  ready,
  saving,
  deleting,
  notFound,
  failure,
}

class TimelineEventState {
  const TimelineEventState({
    this.status = TimelineEventStatus.initial,
    this.userId,
    this.petId,
    this.eventId,
    this.event,
    this.errorMessage,
  });

  final TimelineEventStatus status;
  final EntityId? userId;
  final String? petId;
  final String? eventId;
  final PetEvent? event;
  final String? errorMessage;

  bool get isReady => status == TimelineEventStatus.ready;

  TimelineEventState copyWith({
    TimelineEventStatus? status,
    EntityId? userId,
    String? petId,
    String? eventId,
    PetEvent? event,
    String? errorMessage,
  }) {
    return TimelineEventState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      eventId: eventId ?? this.eventId,
      event: event ?? this.event,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
