/// Requests the user's permission to track their activity across apps and
/// websites (Apple's App Tracking Transparency, ATT).
///
/// PawVault's privacy labels declare data that Apple treats as "used to track",
/// so iOS requires this permission prompt to be shown before that data is
/// collected. Implementations are safe to call on every launch — the system
/// only presents the dialog once and remembers the user's choice afterwards.
abstract interface class TrackingAuthorizationService {
  Future<void> requestAuthorization();
}
