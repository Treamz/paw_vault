import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_paths.dart';
import 'package:paw_vault/features/smart_input/data/datasources/firestore_smart_input_data_source.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';

class FlutterFireSmartInputDataSource implements FirestoreSmartInputDataSource {
  FlutterFireSmartInputDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<SmartMessage>> watchSmartMessages({
    required String userId,
    required String petId,
  }) {
    return _firestore
        .collection(FirestorePaths.smartMessages(userId: userId, petId: petId))
        .snapshots()
        .map((_) => const <SmartMessage>[]);
  }
}
