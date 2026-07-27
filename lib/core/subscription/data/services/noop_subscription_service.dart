import 'package:paw_vault/core/subscription/domain/entities/entitlements.dart';
import 'package:paw_vault/core/subscription/domain/entities/subscription_package.dart';
import 'package:paw_vault/core/subscription/domain/services/subscription_service.dart';

/// [SubscriptionService] for local-first mode. There is no store, so it grants
/// full ("unlocked") access and exposes no packages to purchase.
class NoopSubscriptionService implements SubscriptionService {
  const NoopSubscriptionService();

  @override
  Stream<Entitlements> watchEntitlements() =>
      Stream<Entitlements>.value(Entitlements.unlocked);

  @override
  Future<Entitlements> currentEntitlements() async => Entitlements.unlocked;

  @override
  Future<void> identify(
    String userId, {
    String? email,
    String? displayName,
  }) async {}

  @override
  Future<void> resetIdentity() async {}

  @override
  Future<List<SubscriptionPackage>> offerings() async => const [];

  @override
  Future<Entitlements> purchase(SubscriptionPackage package) async =>
      Entitlements.unlocked;

  @override
  Future<Entitlements> restore() async => Entitlements.unlocked;
}
