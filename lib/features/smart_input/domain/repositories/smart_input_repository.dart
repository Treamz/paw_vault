import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';

abstract interface class SmartInputRepository {
  Future<SmartInputDraft> createDraft(String input);
}
