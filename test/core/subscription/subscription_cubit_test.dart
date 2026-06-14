import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/subscription/data/services/noop_subscription_service.dart';
import 'package:paw_vault/core/subscription/domain/entities/entitlements.dart';
import 'package:paw_vault/core/subscription/domain/entities/subscription_package.dart';
import 'package:paw_vault/core/subscription/domain/services/subscription_service.dart';
import 'package:paw_vault/core/subscription/presentation/cubit/subscription_cubit.dart';

void main() {
  group('NoopSubscriptionService', () {
    test('grants full access and exposes no packages', () async {
      const service = NoopSubscriptionService();

      expect((await service.currentEntitlements()).isPro, isTrue);
      expect(await service.offerings(), isEmpty);
      expect((await service.watchEntitlements().first).isPro, isTrue);
    });
  });

  group('SubscriptionCubit', () {
    test('emits entitlement updates from the service', () async {
      final service = _FakeSubscriptionService();
      final cubit = SubscriptionCubit(service);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.isPro, isFalse);

      service.emit(const Entitlements(isPro: true));
      await Future<void>.delayed(Duration.zero);

      expect(cubit.isPro, isTrue);

      await cubit.close();
    });
  });
}

class _FakeSubscriptionService implements SubscriptionService {
  final StreamController<Entitlements> _controller =
      StreamController<Entitlements>.broadcast();

  void emit(Entitlements entitlements) => _controller.add(entitlements);

  @override
  Stream<Entitlements> watchEntitlements() async* {
    yield Entitlements.free;
    yield* _controller.stream;
  }

  @override
  Future<Entitlements> currentEntitlements() async => Entitlements.free;

  @override
  Future<void> identify(String userId) async {}

  @override
  Future<void> resetIdentity() async {}

  @override
  Future<List<SubscriptionPackage>> offerings() async => const [];

  @override
  Future<Entitlements> purchase(SubscriptionPackage package) async =>
      Entitlements.free;

  @override
  Future<Entitlements> restore() async => Entitlements.free;
}
