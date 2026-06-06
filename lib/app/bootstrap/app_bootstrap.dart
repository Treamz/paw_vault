import 'package:paw_vault/core/auth/application/anonymous_auth_bootstrap.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/firebase/firebase_app_initializer.dart';
import 'package:paw_vault/core/firebase/firebase_instances.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_offline_configurator.dart';

abstract final class AppBootstrap {
  static const useFirebase = bool.fromEnvironment('PAWVAULT_USE_FIREBASE');

  static Future<AppDependencies> createDependencies({
    bool useFirebase = AppBootstrap.useFirebase,
  }) async {
    if (!useFirebase) {
      return AppDependencies.localFirst();
    }

    await FirebaseAppInitializer.initialize();
    final firebase = FirebaseInstances();
    FirestoreOfflineConfigurator.configure(firebase.firestore);
    final dependencies = AppDependencies.firebaseReady(firebase);
    await AnonymousAuthBootstrap.ensureSignedIn(dependencies.authRepository);

    return dependencies;
  }
}
