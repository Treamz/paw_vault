/// Port for product analytics.
///
/// Implementations live in the data layer and wrap the analytics SDK; the
/// presentation layer (route observer, Cubits) depends only on this
/// abstraction. The local-first build uses a no-op implementation so nothing is
/// collected without Firebase.
///
/// Only non-identifying counts and types should be sent — never personal or
/// medical content (names, notes, document text, etc.).
abstract interface class AnalyticsService {
  /// Logs a screen view for [screenName] (typically the route name).
  Future<void> logScreenView(String screenName);

  /// Logs a named product event with optional non-identifying [parameters].
  /// Null parameter values are ignored.
  Future<void> logEvent(String name, {Map<String, Object?>? parameters});

  /// Associates subsequent events with [userId] (a non-identifying id such as
  /// the Firebase uid), or clears it when null.
  Future<void> setUserId(String? userId);
}
