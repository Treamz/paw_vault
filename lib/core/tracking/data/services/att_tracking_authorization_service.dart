import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:paw_vault/core/tracking/domain/services/tracking_authorization_service.dart';

/// App Tracking Transparency implementation backed by the
/// `app_tracking_transparency` plugin. On Android (and other platforms without
/// ATT) the plugin reports [TrackingStatus.notSupported] and the request is a
/// no-op, so this is safe to use everywhere.
class AttTrackingAuthorizationService implements TrackingAuthorizationService {
  const AttTrackingAuthorizationService();

  @override
  Future<void> requestAuthorization() async {
    // The system dialog can only be shown while the app is in the active
    // state; a short delay after launch avoids the request being dropped when
    // it fires before the first frame has settled.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }
}
