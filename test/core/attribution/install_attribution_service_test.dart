import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/attribution/data/services/noop_install_attribution_service.dart';
import 'package:paw_vault/core/attribution/domain/services/install_attribution_service.dart';

void main() {
  group('NoopInstallAttributionService', () {
    test('is an InstallAttributionService that completes without error',
        () async {
      const InstallAttributionService service = NoopInstallAttributionService();

      await expectLater(service.enableCollection(), completes);
    });

    test('is safe to call repeatedly', () async {
      // Callers are promised the call is idempotent, because both the real
      // SDK and this stand-in may be invoked on every launch.
      const InstallAttributionService service = NoopInstallAttributionService();

      await service.enableCollection();
      await expectLater(service.enableCollection(), completes);
    });
  });
}
