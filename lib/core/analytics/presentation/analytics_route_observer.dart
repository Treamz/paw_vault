import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';

/// Navigator observer that reports a screen view to [AnalyticsService] whenever
/// the top-most route changes. Depends only on the analytics port, never the
/// analytics SDK.
class AnalyticsRouteObserver extends AutoRouteObserver {
  AnalyticsRouteObserver(this._analytics);

  final AnalyticsService _analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logScreen(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logScreen(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // Returning to the previous screen counts as a new view of it.
    _logScreen(previousRoute);
  }

  void _logScreen(Route<dynamic>? route) {
    if (route is! PageRoute) return;
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;
    _analytics.logScreenView(name);
  }
}
