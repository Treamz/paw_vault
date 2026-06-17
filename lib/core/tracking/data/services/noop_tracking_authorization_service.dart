import 'package:paw_vault/core/tracking/domain/services/tracking_authorization_service.dart';

/// No-op implementation used in local-first mode, where no analytics or
/// tracking data is collected and the ATT prompt would be meaningless.
class NoopTrackingAuthorizationService implements TrackingAuthorizationService {
  const NoopTrackingAuthorizationService();

  @override
  Future<void> requestAuthorization() async {}
}
