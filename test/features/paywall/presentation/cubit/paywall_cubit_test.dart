import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/subscription/domain/entities/entitlements.dart';
import 'package:paw_vault/core/subscription/domain/entities/subscription_package.dart';
import 'package:paw_vault/core/subscription/domain/services/subscription_service.dart';
import 'package:paw_vault/features/paywall/presentation/cubit/paywall_cubit.dart';

const _annual = SubscriptionPackage(
  id: r'$rc_annual',
  title: 'PawVault Pro (Annual)',
  priceString: r'$29.99',
  period: 'annual',
  hasFreeTrial: true,
  trialDescription: '7 day free',
);

void main() {
  group('PaywallCubit', () {
    test('load exposes the available packages', () async {
      final cubit = PaywallCubit(
        subscriptionService: _FakeSubscriptionService(packages: [_annual]),
      );

      await cubit.load();

      expect(cubit.state.status, PaywallStatus.ready);
      expect(cubit.state.packages, [_annual]);
    });

    test('successful purchase moves to purchased', () async {
      final cubit = PaywallCubit(
        subscriptionService: _FakeSubscriptionService(
          packages: [_annual],
          purchaseResult: const Entitlements(isPro: true),
        ),
      );

      await cubit.purchase(_annual);

      expect(cubit.state.status, PaywallStatus.purchased);
    });

    test('cancelled purchase returns to ready without error', () async {
      final cubit = PaywallCubit(
        subscriptionService: _FakeSubscriptionService(
          throwOnPurchase: const PurchaseCancelledException(),
        ),
      );

      await cubit.purchase(_annual);

      expect(cubit.state.status, PaywallStatus.ready);
      expect(cubit.state.errorMessage, isNull);
    });

    test('failed purchase surfaces an error', () async {
      final cubit = PaywallCubit(
        subscriptionService: _FakeSubscriptionService(
          throwOnPurchase: const PurchaseException('Network error'),
        ),
      );

      await cubit.purchase(_annual);

      expect(cubit.state.status, PaywallStatus.failure);
      expect(cubit.state.errorMessage, 'Network error');
    });

    test('restore with no entitlement reports failure', () async {
      final cubit = PaywallCubit(
        subscriptionService: _FakeSubscriptionService(),
      );

      await cubit.restore();

      expect(cubit.state.status, PaywallStatus.failure);
    });
  });
}

class _FakeSubscriptionService implements SubscriptionService {
  _FakeSubscriptionService({
    this.packages = const [],
    this.purchaseResult = Entitlements.free,
    this.throwOnPurchase,
  }) : restoreResult = Entitlements.free;

  final List<SubscriptionPackage> packages;
  final Entitlements purchaseResult;
  final Entitlements restoreResult;
  final Object? throwOnPurchase;

  @override
  Future<List<SubscriptionPackage>> offerings() async => packages;

  @override
  Future<Entitlements> purchase(SubscriptionPackage package) async {
    final error = throwOnPurchase;
    if (error != null) throw error;
    return purchaseResult;
  }

  @override
  Future<Entitlements> restore() async => restoreResult;

  @override
  Future<Entitlements> currentEntitlements() async => Entitlements.free;

  @override
  Stream<Entitlements> watchEntitlements() =>
      Stream<Entitlements>.value(Entitlements.free);

  @override
  Future<void> identify(String userId) async {}

  @override
  Future<void> resetIdentity() async {}
}
