import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_paths.dart';
import 'package:paw_vault/features/reminders/data/datasources/firestore_reminder_data_source.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';

class FlutterFireReminderDataSource implements FirestoreReminderDataSource {
  FlutterFireReminderDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Reminder>> watchReminders({
    required String userId,
    required String petId,
  }) {
    return _firestore
        .collection(FirestorePaths.reminders(userId: userId, petId: petId))
        .snapshots()
        .map((_) => const <Reminder>[]);
  }
}
