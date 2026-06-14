import 'package:paw_vault/core/subscription/domain/services/paywall_presenter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// [PaywallPresenter] backed by RevenueCat's remote paywalls
/// (`purchases_ui_flutter`). The paywall design comes from the RevenueCat
/// dashboard for the current offering.
class RevenueCatPaywallPresenter implements PaywallPresenter {
  const RevenueCatPaywallPresenter({this.entitlementId = 'pro'});

  /// The entitlement required to skip the paywall.
  final String entitlementId;

  @override
  Future<PaywallOutcome> presentIfNeeded() async {
    final result = await RevenueCatUI.presentPaywallIfNeeded(entitlementId);
    return switch (result) {
      PaywallResult.purchased => PaywallOutcome.purchased,
      PaywallResult.restored => PaywallOutcome.restored,
      PaywallResult.cancelled => PaywallOutcome.cancelled,
      PaywallResult.notPresented => PaywallOutcome.notPresented,
      PaywallResult.error => PaywallOutcome.error,
    };
  }
}
