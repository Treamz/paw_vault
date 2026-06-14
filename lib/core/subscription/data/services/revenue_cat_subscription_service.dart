import 'dart:async';

import 'package:flutter/services.dart' show PlatformException;
import 'package:paw_vault/core/subscription/domain/entities/entitlements.dart';
import 'package:paw_vault/core/subscription/domain/entities/subscription_package.dart';
import 'package:paw_vault/core/subscription/domain/services/subscription_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// [SubscriptionService] backed by RevenueCat (`purchases_flutter`).
///
/// `Purchases.configure(...)` must have been called during bootstrap before
/// this is constructed.
class RevenueCatSubscriptionService implements SubscriptionService {
  RevenueCatSubscriptionService({this.entitlementId = 'pro'}) {
    Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
    unawaited(_seed());
  }

  /// The RevenueCat entitlement identifier that represents Pro.
  final String entitlementId;

  final StreamController<Entitlements> _controller =
      StreamController<Entitlements>.broadcast();
  Entitlements _last = Entitlements.free;
  List<Package> _packages = const [];

  Future<void> _seed() async {
    try {
      _onCustomerInfo(await Purchases.getCustomerInfo());
    } catch (_) {
      // Leave the seeded "free" value; updates will arrive via the listener.
    }
  }

  void _onCustomerInfo(CustomerInfo info) {
    _last = _mapEntitlements(info);
    if (!_controller.isClosed) _controller.add(_last);
  }

  Entitlements _mapEntitlements(CustomerInfo info) {
    final entitlement = info.entitlements.active[entitlementId];
    if (entitlement == null) return Entitlements.free;
    final expiry = entitlement.expirationDate;
    return Entitlements(
      isPro: true,
      activeUntil: expiry == null ? null : DateTime.tryParse(expiry),
      willRenew: entitlement.willRenew,
    );
  }

  @override
  Stream<Entitlements> watchEntitlements() async* {
    yield _last;
    yield* _controller.stream;
  }

  @override
  Future<Entitlements> currentEntitlements() async =>
      _mapEntitlements(await Purchases.getCustomerInfo());

  @override
  Future<void> identify(String userId) async {
    await Purchases.logIn(userId);
  }

  @override
  Future<void> resetIdentity() async {
    await Purchases.logOut();
  }

  @override
  Future<List<SubscriptionPackage>> offerings() async {
    final offerings = await Purchases.getOfferings();
    _packages = offerings.current?.availablePackages ?? const [];
    return _packages.map(_mapPackage).toList();
  }

  @override
  Future<Entitlements> purchase(SubscriptionPackage package) async {
    final storePackage = _packages.where((p) => p.identifier == package.id);
    if (storePackage.isEmpty) {
      throw const PurchaseException('Selected package is no longer available.');
    }
    try {
      final result =
          await Purchases.purchase(PurchaseParams.package(storePackage.first));
      _onCustomerInfo(result.customerInfo);
      return _last;
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        throw const PurchaseCancelledException();
      }
      throw PurchaseException(error.message ?? code.name);
    }
  }

  @override
  Future<Entitlements> restore() async {
    try {
      _onCustomerInfo(await Purchases.restorePurchases());
      return _last;
    } on PlatformException catch (error) {
      throw PurchaseException(error.message ?? 'Restore failed');
    }
  }

  SubscriptionPackage _mapPackage(Package package) {
    final product = package.storeProduct;
    final intro = product.introductoryPrice;
    final hasTrial = intro != null && intro.price == 0;
    return SubscriptionPackage(
      id: package.identifier,
      title: product.title,
      priceString: product.priceString,
      period: package.packageType.name,
      hasFreeTrial: hasTrial,
      trialDescription: hasTrial
          ? '${intro.periodNumberOfUnits} ${intro.periodUnit.name} free'
          : null,
    );
  }
}
