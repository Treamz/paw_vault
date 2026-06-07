import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';

abstract interface class FirestoreSmartInputDataSource {
  Stream<List<SmartMessage>> watchSmartMessages({
    required String userId,
    required String petId,
  });

  Future<SmartMessage?> getSmartMessage({
    required String userId,
    required String petId,
    required String messageId,
  });

  Future<void> saveSmartMessage(SmartMessage message);

  Future<void> deleteSmartMessage({
    required String userId,
    required String petId,
    required String messageId,
  });
}
