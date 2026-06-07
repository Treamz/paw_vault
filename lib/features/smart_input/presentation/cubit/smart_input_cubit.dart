import 'package:flutter_bloc/flutter_bloc.dart';
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
  })  : _smartInputRepository = smartInputRepository,
        _authRepository = authRepository,
        super(const SmartInputState());

  final SmartInputRepository _smartInputRepository;
  final AuthRepository _authRepository;

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
      const SmartInputState(status: SmartInputStatus.processing),
    );

    try {
      final draft = await _smartInputRepository.createDraft(input);
      emit(
        SmartInputState(
          status: SmartInputStatus.review,
          draft: draft,
        ),
      );
    } catch (error) {
      emit(
        SmartInputState(
          status: SmartInputStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Persists the reviewed draft as a confirmed [SmartMessage]. Only called
  /// after the user explicitly approves the AI-generated draft.
  Future<void> confirmDraft(String petId) async {
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
      final user = await _authRepository.currentUser() ??
          await _authRepository.signInAnonymously();
      final now = DateTime.now();

      final message = SmartMessage(
        id: EntityId('${now.microsecondsSinceEpoch}'),
        userId: EntityId(user.id),
        petId: EntityId(petId),
        originalText: draft.originalText,
        detectedIntent: draft.detectedIntent,
        extractedData: draft.extractedData,
        suggestedActions: draft.suggestedActions,
        confidence: draft.confidence ?? 0,
        status: SmartMessageStatus.confirmed,
        createdAt: UtcDateTime(now),
      );

      await _smartInputRepository.saveSmartMessage(message);

      emit(const SmartInputState(status: SmartInputStatus.confirmed));
    } catch (error) {
      emit(
        state.copyWith(
          status: SmartInputStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
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

class SmartInputState {
  const SmartInputState({
    this.status = SmartInputStatus.idle,
    this.draft,
    this.errorMessage,
  });

  final SmartInputStatus status;
  final SmartInputDraft? draft;
  final String? errorMessage;

  bool get isProcessing => status == SmartInputStatus.processing;
  bool get isSaving => status == SmartInputStatus.saving;
  bool get hasDraft =>
      draft != null &&
      (status == SmartInputStatus.review || status == SmartInputStatus.saving);

  SmartInputState copyWith({
    SmartInputStatus? status,
    SmartInputDraft? draft,
    String? errorMessage,
  }) {
    return SmartInputState(
      status: status ?? this.status,
      draft: draft ?? this.draft,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
