import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/tracking/data/services/noop_tracking_authorization_service.dart';
import 'package:paw_vault/core/tracking/domain/services/tracking_authorization_service.dart';

void main() {
  group('NoopTrackingAuthorizationService', () {
    test('is a TrackingAuthorizationService that completes without error',
        () async {
      const TrackingAuthorizationService service =
          NoopTrackingAuthorizationService();

      await expectLater(service.requestAuthorization(), completes);
    });
  });
}
