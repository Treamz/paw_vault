/// The result of presenting the paywall.
enum PaywallOutcome { purchased, restored, cancelled, notPresented, error }

/// Port for presenting the subscription paywall.
///
/// The paywall itself is designed and configured in the RevenueCat dashboard —
/// it is not hard-coded in the app. Implementations live in the data layer and
/// wrap the RevenueCat UI SDK; the presentation layer depends only on this
/// abstraction.
abstract interface class PaywallPresenter {
  /// Presents the configured paywall when the user does not have the required
  /// entitlement, and returns the [PaywallOutcome].
  Future<PaywallOutcome> presentIfNeeded();
}
