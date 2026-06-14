import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';

/// [AnalyticsService] backed by Firebase Analytics (Google Analytics for
/// Firebase).
class FirebaseAnalyticsService implements AnalyticsService {
  const FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logScreenView(String screenName) {
    return _analytics.logScreenView(screenName: screenName);
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) {
    return _analytics.logEvent(
      name: name,
      parameters: _sanitize(parameters),
    );
  }

  @override
  Future<void> setUserId(String? userId) => _analytics.setUserId(id: userId);

  /// Firebase event parameters must be non-null `String`/`num` values, so drop
  /// nulls and coerce everything else to a string.
  Map<String, Object>? _sanitize(Map<String, Object?>? parameters) {
    if (parameters == null) return null;
    final result = <String, Object>{};
    for (final entry in parameters.entries) {
      final value = entry.value;
      if (value == null) continue;
      result[entry.key] = value is num ? value : value.toString();
    }
    return result.isEmpty ? null : result;
  }
}
