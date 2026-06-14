/// A purchasable subscription option, mapped from a store package. Holds only
/// display-ready, SDK-agnostic data; the data layer resolves it back to the
/// underlying store package by [id] at purchase time.
class SubscriptionPackage {
  const SubscriptionPackage({
    required this.id,
    required this.title,
    required this.priceString,
    required this.period,
    this.hasFreeTrial = false,
    this.trialDescription,
  });

  /// Store package identifier (e.g. `$rc_annual`).
  final String id;

  /// Localized product title.
  final String title;

  /// Localized price, e.g. `$29.99`.
  final String priceString;

  /// Billing period label, e.g. `annual`.
  final String period;

  final bool hasFreeTrial;

  /// Localized trial description, e.g. `7 days free`.
  final String? trialDescription;
}
