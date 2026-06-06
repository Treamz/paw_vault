import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';

class SmartInputCubit extends Cubit<SmartInputState> {
  SmartInputCubit(this._smartInputRepository) : super(const SmartInputState());

  final SmartInputRepository _smartInputRepository;

  Future<void> createDraft(String input) async {
    final draft = await _smartInputRepository.createDraft(input);
    emit(SmartInputState(draft: draft));
  }
}

class SmartInputState {
  const SmartInputState({this.draft});

  final SmartInputDraft? draft;
}
