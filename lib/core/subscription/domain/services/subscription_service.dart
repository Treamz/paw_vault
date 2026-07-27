import 'package:paw_vault/core/subscription/domain/entities/entitlements.dart';
import 'package:paw_vault/core/subscription/domain/entities/subscription_package.dart';

/// Port for subscription/entitlement management ("PawVault Pro").
///
/// Implementations live in the data layer and wrap the purchases SDK; the
/// presentation layer depends only on this abstraction. The local-first build
/// uses a no-op implementation that grants full access (there is no store).
abstract interface class SubscriptionService {
  /// Reactive entitlement state; emits the current value immediately.
  Stream<Entitlements> watchEntitlements();

  /// The current entitlement state.
  Future<Entitlements> currentEntitlements();

  /// Associates purchases with a stable app user id (the Firebase uid) so the
  /// subscription follows the account across devices. [email] and
  /// [displayName], when known, are attached as subscriber attributes so the
  /// customer is identifiable in the store dashboard.
  Future<void> identify(String userId, {String? email, String? displayName});

  /// Returns to an anonymous purchaser (on sign-out).
  Future<void> resetIdentity();

  /// The packages available to purchase in the current offering.
  Future<List<SubscriptionPackage>> offerings();

  /// Purchases [package]; returns the updated entitlements.
  ///
  /// Throws [PurchaseCancelledException] when the user cancels and
  /// [PurchaseException] on any other failure.
  Future<Entitlements> purchase(SubscriptionPackage package);

  /// Restores previous purchases; returns the updated entitlements.
  Future<Entitlements> restore();
}

/// Thrown when the user cancels the purchase flow.
class PurchaseCancelledException implements Exception {
  const PurchaseCancelledException();
}

/// Thrown when a purchase or restore fails for a non-cancellation reason.
class PurchaseException implements Exception {
  const PurchaseException(this.message);

  final String message;

  @override
  String toString() => 'PurchaseException: $message';
}
