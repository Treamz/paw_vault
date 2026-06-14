import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';

/// [AnalyticsService] that collects nothing. Used in local-first mode so the
/// app runs without Firebase and without sending any analytics.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> logScreenView(String screenName) async {}

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {}

  @override
  Future<void> setUserId(String? userId) async {}
}
