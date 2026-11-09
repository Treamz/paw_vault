import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/utils/text_search.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';

class TimelineCubit extends Cubit<TimelineState> {
  TimelineCubit({
    required TimelineRepository timelineRepository,
    required AuthRepository authRepository,
  })  : _timelineRepository = timelineRepository,
        _authRepository = authRepository,
        super(const TimelineState());

  final TimelineRepository _timelineRepository;
  final AuthRepository _authRepository;
  StreamSubscription<List<PetEvent>>? _eventsSubscription;

  Future<void> load(String petId) async {
    emit(TimelineState(status: TimelineStatus.loading, petId: petId));

    try {
      await _timelineRepository.initialize();
      final user = await _authRepository.currentUser() ??
          await _authRepository.signInAnonymously();
      final userId = EntityId(user.id);
      final entityPetId = EntityId(petId);

      await _eventsSubscription?.cancel();
      _eventsSubscription = _timelineRepository
          .watchEvents(userId: userId, petId: entityPetId)
          .listen(
        (events) {
          emit(
            TimelineState(
              status: TimelineStatus.ready,
              userId: userId,
              petId: petId,
              events: [...events]..sort((a, b) {
                  final aTime = a.createdAt?.value ?? a.date.value;
                  final bTime = b.createdAt?.value ?? b.date.value;
                  return bTime.compareTo(aTime);
                }),
            ),
          );
        },
        onError: (Object error) {
          emit(
            TimelineState(
              status: TimelineStatus.failure,
              userId: userId,
              petId: petId,
              errorMessage: error.toString(),
            ),
          );
        },
      );
    } catch (error) {
      emit(
        TimelineState(
          status: TimelineStatus.failure,
          petId: petId,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void setEventTypeFilter(PetEventType? eventType) {
    emit(
      state.copyWith(
        filterEventType: eventType,
        clearEventTypeFilter: eventType == null,
      ),
    );
  }

  void setDateRangeFilter({DateTime? startDate, DateTime? endDate}) {
    emit(
      state.copyWith(
        filterStartDate: startDate,
        filterEndDate: endDate,
        clearStartDateFilter: startDate == null,
        clearEndDateFilter: endDate == null,
      ),
    );
  }

  /// Narrows the timeline to events matching [query].
  ///
  /// Kept out of [clearFilters] for the same reason as on the documents
  /// list: the search box stays on screen, so clearing the type and date
  /// filters must not empty it behind the user's back.
  void setQuery(String query) {
    emit(state.copyWith(query: query));
  }

  void clearFilters() {
    emit(
      state.copyWith(
        clearEventTypeFilter: true,
        clearStartDateFilter: true,
        clearEndDateFilter: true,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _eventsSubscription?.cancel();
    return super.close();
  }
}

enum TimelineStatus {
  initial,
  loading,
  ready,
  failure,
}

class TimelineState {
  const TimelineState({
    this.status = TimelineStatus.initial,
    this.userId,
    this.petId,
    this.events = const [],
    this.filterEventType,
    this.filterStartDate,
    this.filterEndDate,
    this.query = '',
    this.errorMessage,
  });

  final TimelineStatus status;
  final EntityId? userId;
  final String? petId;
  final List<PetEvent> events;
  final PetEventType? filterEventType;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;

  /// The free-text search, empty when nothing is being searched for.
  final String query;

  final String? errorMessage;

  bool get isReady => status == TimelineStatus.ready;

  List<PetEvent> get filteredEvents {
    var filtered = events;

    if (filterEventType != null) {
      filtered =
          filtered.where((event) => event.type == filterEventType).toList();
    }

    if (filterStartDate != null) {
      filtered = filtered
          .where((event) => !event.date.value.isBefore(filterStartDate!))
          .toList();
    }

    if (filterEndDate != null) {
      filtered = filtered
          .where((event) => !event.date.value.isAfter(filterEndDate!))
          .toList();
    }

    // An event carries far less text than a document -- no scan behind it --
    // so the search covers everything it does have that a person would
    // remember it by.
    if (query.trim().isNotEmpty) {
      filtered = filtered
          .where(
            (event) => matchesSearchQuery(query, [
              event.title,
              event.type.name,
              event.description,
            ]),
          )
          .toList();
    }

    return filtered;
  }

  TimelineState copyWith({
    TimelineStatus? status,
    EntityId? userId,
    String? petId,
    List<PetEvent>? events,
    PetEventType? filterEventType,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    String? query,
    String? errorMessage,
    bool clearEventTypeFilter = false,
    bool clearStartDateFilter = false,
    bool clearEndDateFilter = false,
  }) {
    return TimelineState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      events: events ?? this.events,
      filterEventType: clearEventTypeFilter
          ? null
          : (filterEventType ?? this.filterEventType),
      filterStartDate: clearStartDateFilter
          ? null
          : (filterStartDate ?? this.filterStartDate),
      filterEndDate:
          clearEndDateFilter ? null : (filterEndDate ?? this.filterEndDate),
      // No clear flag: an empty query already means "not searching".
      query: query ?? this.query,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
