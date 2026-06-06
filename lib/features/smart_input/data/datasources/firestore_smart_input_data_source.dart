import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';

abstract interface class FirestoreSmartInputDataSource {
  Stream<List<SmartMessage>> watchSmartMessages({
    required String userId,
    required String petId,
  });
}
