/// Canonical analytics event names and parameter keys.
///
/// Names use snake_case and stay under Firebase's 40-character limit. Only
/// non-identifying counts and types are ever sent as parameters — never names,
/// notes, document text, or other personal/medical content.
abstract final class AnalyticsEvents {
  static const petCreated = 'pet_created';
  static const timelineEventAdded = 'timeline_event_added';
  static const documentUploaded = 'document_uploaded';
  static const reminderCreated = 'reminder_created';
  static const smartInputUsed = 'smart_input_used';
  static const vetSummaryExported = 'vet_summary_exported';

  /// Firebase's recommended sign-in event; pair with [paramMethod].
  static const login = 'login';
}

abstract final class AnalyticsParams {
  static const type = 'type';
  static const method = 'method';
}
