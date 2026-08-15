import 'dart:io';

import 'package:paw_vault/core/auth/application/anonymous_auth_bootstrap.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
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
    final (subscriptionService, paywallPresenter) =
        await _configureSubscriptions();
    final dependencies = AppDependencies.firebaseReady(
      firebase,
      subscriptionService: subscriptionService,
      paywallPresenter: paywallPresenter,
    );
    await AnonymousAuthBootstrap.ensureSignedIn(dependencies.authRepository);
    _bindSubscriptionIdentity(dependencies, subscriptionService);

    return dependencies;
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
  static Future<(SubscriptionService, PaywallPresenter)>
      _configureSubscriptions() async {
    final apiKey = _revenueCatApiKey;
    if (apiKey.isEmpty) {
      return (const NoopSubscriptionService(), const NoopPaywallPresenter());
    }
    await Purchases.configure(PurchasesConfiguration(apiKey));
    return (
      RevenueCatSubscriptionService(),
      const RevenueCatPaywallPresenter(),
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
