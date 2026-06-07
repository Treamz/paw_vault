import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_paths.dart';
import 'package:paw_vault/features/reminders/data/datasources/firestore_reminder_data_source.dart';
import 'package:paw_vault/features/reminders/data/mappers/reminder_firestore_mapper.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';

class FlutterFireReminderDataSource implements FirestoreReminderDataSource {
  FlutterFireReminderDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> completeReminder({
    required String userId,
    required String petId,
    required String reminderId,
  }) async {
    await _reminderDocument(
      userId: userId,
      petId: petId,
      reminderId: reminderId,
    ).update({
      'isCompleted': true,
      'updatedAt': FirestoreMapping.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteReminder({
    required String userId,
    required String petId,
    required String reminderId,
  }) async {
    await _reminderDocument(
      userId: userId,
      petId: petId,
      reminderId: reminderId,
    ).delete();
  }

  @override
  Future<Reminder?> getReminder({
    required String userId,
    required String petId,
    required String reminderId,
  }) async {
    final snapshot = await _reminderDocument(
      userId: userId,
      petId: petId,
      reminderId: reminderId,
    ).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return ReminderFirestoreMapper.fromFirestore(
      id: EntityId(snapshot.id),
      data: data,
    );
  }

  @override
  Future<void> saveReminder(Reminder reminder) async {
    final document = _reminderDocument(
      userId: reminder.userId.value,
      petId: reminder.petId.value,
      reminderId: reminder.id.value,
    );
    final snapshot = await document.get();
    final data = ReminderFirestoreMapper.toFirestore(reminder)
      ..remove('createdAt')
      ..remove('updatedAt')
      ..['updatedAt'] = FirestoreMapping.serverTimestamp();

    if (!snapshot.exists) {
      data['createdAt'] = FirestoreMapping.serverTimestamp();
    }

    await document.set(data, SetOptions(merge: true));
  }

  @override
  Stream<List<Reminder>> watchReminders({
    required String userId,
    required String petId,
  }) {
    return _firestore
        .collection(FirestorePaths.reminders(userId: userId, petId: petId))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => ReminderFirestoreMapper.fromFirestore(
                  id: EntityId(document.id),
                  data: document.data(),
                ),
              )
              .toList(),
        );
  }

  DocumentReference<Map<String, Object?>> _reminderDocument({
    required String userId,
    required String petId,
    required String reminderId,
  }) {
    return _firestore.doc(
      '${FirestorePaths.reminders(userId: userId, petId: petId)}/$reminderId',
    );
  }
}
