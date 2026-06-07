import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';

class SmartInputCubit extends Cubit<SmartInputState> {
  SmartInputCubit(this._smartInputRepository) : super(const SmartInputState());

  final SmartInputRepository _smartInputRepository;

  /// Sends [input] to the AI repository and emits the resulting draft for
  /// review. The draft is never persisted here — saving requires explicit
  /// user confirmation in a later step.
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
}

enum SmartInputStatus {
  idle,
  processing,
  review,
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
  bool get hasDraft => status == SmartInputStatus.review && draft != null;

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
