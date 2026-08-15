import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/analytics/data/services/noop_analytics_service.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_events.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';

class SmartInputCubit extends Cubit<SmartInputState> {
  SmartInputCubit({
    required SmartInputRepository smartInputRepository,
    required AuthRepository authRepository,
    AnalyticsService? analytics,
  })  : _smartInputRepository = smartInputRepository,
        _authRepository = authRepository,
        _analytics = analytics ?? const NoopAnalyticsService(),
        super(const SmartInputState());

  final SmartInputRepository _smartInputRepository;
  final AuthRepository _authRepository;
  final AnalyticsService _analytics;

  /// Removes a confirmed analysis from the history.
  Future<void> deleteMessage(SmartMessage message) async {
    try {
      await _smartInputRepository.deleteSmartMessage(
        userId: message.userId,
        petId: message.petId,
        messageId: message.id,
      );
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  StreamSubscription<List<SmartMessage>>? _messagesSubscription;
  EntityId? _userId;

  /// Subscribes to the pet's saved smart messages for the history list.
  Future<void> load(String petId) async {
    emit(state.copyWith(historyStatus: SmartHistoryStatus.loading));

    try {
      final user = await _currentUserId();
      await _messagesSubscription?.cancel();
      _messagesSubscription = _smartInputRepository
          .watchSmartMessages(userId: user, petId: EntityId(petId))
          .listen(
        (messages) {
          final sorted = [...messages]..sort((a, b) {
              final aTime = a.createdAt?.value;
              final bTime = b.createdAt?.value;
              if (aTime == null || bTime == null) {
                return aTime == null ? 1 : -1;
              }
              return bTime.compareTo(aTime);
            });
          emit(
            state.copyWith(
              historyStatus: SmartHistoryStatus.ready,
              messages: sorted,
            ),
          );
        },
        onError: (Object error) {
          emit(
            state.copyWith(
              historyStatus: SmartHistoryStatus.failure,
              historyError: error.toString(),
            ),
          );
        },
      );
    } catch (error) {
      emit(
        state.copyWith(
          historyStatus: SmartHistoryStatus.failure,
          historyError: error.toString(),
        ),
      );
    }
  }

  /// Sends [input] to the AI repository and emits the resulting draft for
  /// review. The draft is never persisted here — saving requires explicit
  /// user confirmation via [confirmDraft].
  Future<void> submit(String input) async {
    if (input.trim().isEmpty) {
      emit(
        state.copyWith(
          status: SmartInputStatus.failure,
          errorMessage: 'Enter some text to analyze.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SmartInputStatus.processing,
        clearDraft: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final draft = await _smartInputRepository.createDraft(input);
      _analytics.logEvent(AnalyticsEvents.smartInputUsed);
      emit(
        state.copyWith(
          status: SmartInputStatus.review,
          draft: draft,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: SmartInputStatus.failure,
          errorMessage: error.toString(),
          clearDraft: true,
        ),
      );
    }
  }

  /// Persists the reviewed draft as a confirmed [SmartMessage]. Only called
  /// after the user explicitly approves the AI-generated draft.
  Future<void> confirmDraft(
    String petId, {
    Map<String, Object?>? extractedData,
  }) async {
    final draft = state.draft;
    if (draft == null || state.status != SmartInputStatus.review) {
      emit(
        state.copyWith(
          status: SmartInputStatus.failure,
          errorMessage: 'No draft to confirm.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: SmartInputStatus.saving));

    try {
      final userId = await _currentUserId();
      final now = DateTime.now();

      final message = SmartMessage(
        id: EntityId('${now.microsecondsSinceEpoch}'),
        userId: userId,
        petId: EntityId(petId),
        originalText: draft.originalText,
        detectedIntent: draft.detectedIntent,
        // The user may have corrected or added details during review.
        extractedData: extractedData ?? draft.extractedData,
        suggestedActions: draft.suggestedActions,
        confidence: draft.confidence ?? 0,
        status: SmartMessageStatus.confirmed,
        createdAt: UtcDateTime(now),
      );

      await _smartInputRepository.saveSmartMessage(message);

      emit(
        state.copyWith(
          status: SmartInputStatus.confirmed,
          clearDraft: true,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: SmartInputStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Discards the current draft without saving anything, returning to idle.
  void dismissDraft() {
    emit(
      state.copyWith(
        status: SmartInputStatus.idle,
        clearDraft: true,
        clearErrorMessage: true,
      ),
    );
  }

  Future<EntityId> _currentUserId() async {
    final cached = _userId;
    if (cached != null) return cached;
    final user = await _authRepository.currentUser() ??
        await _authRepository.signInAnonymously();
    final id = EntityId(user.id);
    _userId = id;
    return id;
  }

  @override
  Future<void> close() async {
    await _messagesSubscription?.cancel();
    return super.close();
  }
}

enum SmartInputStatus {
  idle,
  processing,
  review,
  saving,
  confirmed,
  failure,
}

enum SmartHistoryStatus {
  loading,
  ready,
  failure,
}

class SmartInputState {
  const SmartInputState({
    this.status = SmartInputStatus.idle,
    this.draft,
    this.errorMessage,
    this.historyStatus = SmartHistoryStatus.loading,
    this.messages = const [],
    this.historyError,
  });

  final SmartInputStatus status;
  final SmartInputDraft? draft;
  final String? errorMessage;
  final SmartHistoryStatus historyStatus;
  final List<SmartMessage> messages;
  final String? historyError;

  bool get isProcessing => status == SmartInputStatus.processing;
  bool get isSaving => status == SmartInputStatus.saving;
  bool get hasDraft =>
      draft != null &&
      (status == SmartInputStatus.review || status == SmartInputStatus.saving);

  SmartInputState copyWith({
    SmartInputStatus? status,
    SmartInputDraft? draft,
    String? errorMessage,
    SmartHistoryStatus? historyStatus,
    List<SmartMessage>? messages,
    String? historyError,
    bool clearDraft = false,
    bool clearErrorMessage = false,
  }) {
    return SmartInputState(
      status: status ?? this.status,
      draft: clearDraft ? null : (draft ?? this.draft),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      historyStatus: historyStatus ?? this.historyStatus,
      messages: messages ?? this.messages,
      historyError: historyError ?? this.historyError,
    );
  }
}
