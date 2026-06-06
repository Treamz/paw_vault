import 'package:firebase_core/firebase_core.dart';
import 'package:paw_vault/firebase_options.dart';

abstract final class FirebaseAppInitializer {
  static Future<void> initialize() {
    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
