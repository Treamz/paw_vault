import 'package:cloud_firestore/cloud_firestore.dart';

abstract final class FirestoreOfflineConfigurator {
  static const cacheSizeBytes = Settings.CACHE_SIZE_UNLIMITED;

  static void configure(FirebaseFirestore firestore) {
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: cacheSizeBytes,
    );
  }
}
