import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/analytics/data/services/noop_analytics_service.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/analytics/presentation/analytics_route_observer.dart';

void main() {
  group('AnalyticsRouteObserver', () {
    test('logs a screen view on push using the route name', () {
      final analytics = _RecordingAnalytics();
      final observer = AnalyticsRouteObserver(analytics);

      observer.didPush(_route('PetListRoute'), null);

      expect(analytics.screenViews, ['PetListRoute']);
    });

    test('logs the revealed route on pop', () {
      final analytics = _RecordingAnalytics();
      final observer = AnalyticsRouteObserver(analytics);

      observer.didPop(_route('PetFormRoute'), _route('PetListRoute'));

      expect(analytics.screenViews, ['PetListRoute']);
    });

    test('logs the new route on replace', () {
      final analytics = _RecordingAnalytics();
      final observer = AnalyticsRouteObserver(analytics);

      observer.didReplace(
        newRoute: _route('AccountRoute'),
        oldRoute: _route('PetListRoute'),
      );

      expect(analytics.screenViews, ['AccountRoute']);
    });

    test('ignores routes without a name', () {
      final analytics = _RecordingAnalytics();
      final observer = AnalyticsRouteObserver(analytics);

      observer.didPush(_route(null), null);

      expect(analytics.screenViews, isEmpty);
    });
  });

  group('NoopAnalyticsService', () {
    test('does nothing and never throws', () async {
      const service = NoopAnalyticsService();
      await service.logScreenView('PetListRoute');
      await service.logEvent('pet_created', parameters: {'species': 'dog'});
      await service.setUserId('user-1');
    });
  });
}

PageRoute<void> _route(String? name) {
  return MaterialPageRoute<void>(
    settings: RouteSettings(name: name),
    builder: (_) => const SizedBox.shrink(),
  );
}

class _RecordingAnalytics implements AnalyticsService {
  final List<String> screenViews = [];

  @override
  Future<void> logScreenView(String screenName) async {
    screenViews.add(screenName);
  }

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {}

  @override
  Future<void> setUserId(String? userId) async {}
}
