import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:paw_vault/core/attribution/data/services/noop_install_attribution_service.dart';
import 'package:paw_vault/core/attribution/data/services/revenue_cat_install_attribution_service.dart';
import 'package:paw_vault/core/attribution/domain/services/install_attribution_service.dart';
import 'package:paw_vault/core/auth/application/anonymous_auth_bootstrap.dart';
import 'package:paw_vault/core/dev/dev_seeder.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firebase_app_initializer.dart';
import 'package:paw_vault/core/firebase/firebase_instances.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_offline_configurator.dart';
import 'package:paw_vault/core/subscription/data/services/noop_paywall_presenter.dart';
import 'package:paw_vault/core/subscription/data/services/noop_subscription_service.dart';
import 'package:paw_vault/core/subscription/data/services/revenue_cat_paywall_presenter.dart';
import 'package:paw_vault/core/subscription/data/services/revenue_cat_subscription_service.dart';
import 'package:paw_vault/core/subscription/domain/services/paywall_presenter.dart';
import 'package:paw_vault/core/subscription/domain/services/subscription_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

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
    final (subscriptionService, paywallPresenter, installAttributionService) =
        await _configureSubscriptions();
    final dependencies = AppDependencies.firebaseReady(
      firebase,
      subscriptionService: subscriptionService,
      paywallPresenter: paywallPresenter,
      installAttributionService: installAttributionService,
    );
    await AnonymousAuthBootstrap.ensureSignedIn(dependencies.authRepository);
    _bindSubscriptionIdentity(dependencies, subscriptionService);
    _seedWhenSignedIn(dependencies);

    return dependencies;
  }

  /// Fills an empty account with sample data in debug builds when
  /// `--dart-define=PAWVAULT_SEED=true` is passed. See `docs/TEST_ACCOUNT.md`.
  ///
  /// Follows the auth stream rather than seeding once at launch. The app starts
  /// anonymous and only later signs in, and signing into an account that
  /// already exists yields a *different* uid — so a one-shot seed at launch
  /// would fill the anonymous account and leave the one you logged into empty.
  ///
  /// [DevSeeder.seedIfEmpty] is idempotent, so re-firing on every auth change
  /// is harmless.
  static void _seedWhenSignedIn(AppDependencies dependencies) {
    if (!DevSeeder.isEnabled) {
      return;
    }

    final seeder = DevSeeder(
      petRepository: dependencies.petRepository,
      timelineRepository: dependencies.timelineRepository,
      documentRepository: dependencies.documentRepository,
      reminderRepository: dependencies.reminderRepository,
      smartInputRepository: dependencies.smartInputRepository,
      pawCheckRepository: dependencies.pawCheckRepository,
      weightEntryRepository: dependencies.weightEntryRepository,
    );

    var seeding = false;

    dependencies.authRepository.watchCurrentUser().listen((user) async {
      if (user == null || seeding) {
        return;
      }

      seeding = true;
      try {
        final seeded = await seeder.seedIfEmpty(EntityId(user.id));
        debugPrint(
          seeded
              ? 'Dev seeding: sample data written for ${user.id}.'
              : 'Dev seeding: ${user.id} already has pets, skipped.',
        );
      } catch (error, stackTrace) {
        // Best effort: a seeding failure must not stop the app from running,
        // or a bad dev flag would look like a broken build.
        debugPrint('Dev seeding failed: $error\n$stackTrace');
      } finally {
        seeding = false;
      }
    });
  }

  /// Keeps RevenueCat logged in as the current Firebase user from app launch,
  /// so entitlements granted to that uid are visible before the user ever
  /// opens the Account screen.
  static void _bindSubscriptionIdentity(
    AppDependencies dependencies,
    SubscriptionService subscriptionService,
  ) {
    dependencies.authRepository.watchCurrentUser().listen((user) {
      if (user != null) {
        subscriptionService.identify(
          user.id,
          email: user.email,
          displayName: user.displayName,
        );
      } else {
        subscriptionService.resetIdentity();
      }
    });
  }

  /// Configures RevenueCat when a public SDK key is provided via dart-define;
  /// otherwise falls back to the no-op services so the app still runs. The
  /// paywall UI itself is configured in the RevenueCat dashboard.
  static Future<
      (
        SubscriptionService,
        PaywallPresenter,
        InstallAttributionService,
      )> _configureSubscriptions() async {
    final apiKey = _revenueCatApiKey;
    if (apiKey.isEmpty) {
      return (
        const NoopSubscriptionService(),
        const NoopPaywallPresenter(),
        const NoopInstallAttributionService(),
      );
    }
    await Purchases.configure(PurchasesConfiguration(apiKey));
    return (
      RevenueCatSubscriptionService(),
      const RevenueCatPaywallPresenter(),
      // Collection itself is enabled later, after the ATT prompt resolves —
      // see the post-frame callback in `app.dart`.
      const RevenueCatInstallAttributionService(),
    );
  }

  static String get _revenueCatApiKey {
    if (Platform.isIOS) {
      return const String.fromEnvironment('REVENUECAT_IOS_API_KEY');
    }
    if (Platform.isAndroid) {
      return const String.fromEnvironment('REVENUECAT_ANDROID_API_KEY');
    }
    return '';
  }
}
