import 'package:flutter/foundation.dart' show debugPrint;
import 'package:paw_vault/core/subscription/domain/services/paywall_presenter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// [PaywallPresenter] backed by RevenueCat's remote paywalls
/// (`purchases_ui_flutter`). The paywall design comes from the RevenueCat
/// dashboard for the current offering.
class RevenueCatPaywallPresenter implements PaywallPresenter {
  const RevenueCatPaywallPresenter();

  @override
  Future<PaywallOutcome> presentIfNeeded() async {
    // The app has a single Pro tier, so any active entitlement unlocks it.
    // Checking ourselves (instead of presentPaywallIfNeeded's exact-id match)
    // keeps dashboard entitlement naming from re-gating paying users.
    try {
      final info = await Purchases.getCustomerInfo();
      if (info.entitlements.active.isNotEmpty) {
        debugPrint(
          'RevenueCat: active entitlements '
          '${info.entitlements.active.keys.toList()} — skipping paywall',
        );
        return PaywallOutcome.notPresented;
      }
    } catch (_) {
      // Fall through and present; the paywall itself handles offline states.
    }

    final result = await RevenueCatUI.presentPaywall();
    return switch (result) {
      PaywallResult.purchased => PaywallOutcome.purchased,
      PaywallResult.restored => PaywallOutcome.restored,
      PaywallResult.cancelled => PaywallOutcome.cancelled,
      PaywallResult.notPresented => PaywallOutcome.notPresented,
      PaywallResult.error => PaywallOutcome.error,
    };
  }
}
