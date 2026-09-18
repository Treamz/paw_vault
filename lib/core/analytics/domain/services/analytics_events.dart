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

  /// A paw scan produced a reviewable result; pair with
  /// [AnalyticsParams.level] and [AnalyticsParams.photoCount].
  static const pawScanAnalyzed = 'paw_scan_analyzed';

  /// A paw scan was rejected before any verdict was shown (not a paw, photo
  /// unusable, or the model refused); pair with [AnalyticsParams.type].
  static const pawScanRejected = 'paw_scan_rejected';

  /// The safety filter had to rewrite model output. A rise here means the
  /// prompt or the model has drifted and is worth treating as an alarm, not a
  /// statistic.
  static const pawScanFiltered = 'paw_scan_filtered';

  /// The owner confirmed a paw check into the journal; pair with
  /// [AnalyticsParams.level].
  static const pawCheckLogged = 'paw_check_logged';

  /// Firebase's recommended sign-in event; pair with [AnalyticsParams.method].
  static const login = 'login';

  static const paywallViewed = 'paywall_viewed';
  static const purchaseCompleted = 'purchase_completed';
  static const purchaseRestored = 'purchase_restored';
}

abstract final class AnalyticsParams {
  static const type = 'type';
  static const method = 'method';
  static const product = 'product';

  /// A [PawAttentionLevel] name. Safe to send: it is a fixed bucket, not
  /// content — observation text is never logged.
  static const level = 'level';

  static const photoCount = 'photo_count';
}
