import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_paths.dart';
import 'package:paw_vault/features/timeline/data/datasources/firestore_timeline_data_source.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';

class FlutterFireTimelineDataSource implements FirestoreTimelineDataSource {
  FlutterFireTimelineDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<PetEvent>> watchEvents({
    required String userId,
    required String petId,
  }) {
    return _firestore
        .collection(FirestorePaths.events(userId: userId, petId: petId))
        .snapshots()
        .map((_) => const <PetEvent>[]);
  }
}
