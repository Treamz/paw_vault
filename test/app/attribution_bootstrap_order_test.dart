import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/attribution/domain/services/install_attribution_service.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/tracking/domain/services/tracking_authorization_service.dart';

void main() {
  testWidgets('enables attribution collection after the ATT prompt resolves',
      (tester) async {
    // This ordering is invisible at runtime and has no log line, so it is the
    // kind of thing a tidy-up refactor silently breaks. AdServices attribution
    // needs no ATT consent, but Apple returns richer "Detailed" data once ATT
    // has been resolved, and RevenueCat caches the first token it posts — so
    // enabling collection before the prompt permanently downgrades the data
    // for that install.
    final order = <String>[];
    final tracking = _RecordingTrackingAuthorizationService(order);
    final attribution = _RecordingInstallAttributionService(order);

    await tester.pumpWidget(
      PawVaultApp(
        dependencies: AppDependencies.localFirst(
          trackingAuthorizationService: tracking,
          installAttributionService: attribution,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(order, ['att', 'attribution']);
  });

  testWidgets('requests each exactly once per launch', (tester) async {
    final order = <String>[];
    final tracking = _RecordingTrackingAuthorizationService(order);
    final attribution = _RecordingInstallAttributionService(order);

    await tester.pumpWidget(
      PawVaultApp(
        dependencies: AppDependencies.localFirst(
          trackingAuthorizationService: tracking,
          installAttributionService: attribution,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tracking.callCount, 1);
    expect(attribution.callCount, 1);
  });

  testWidgets('enables attribution even when ATT is slow to resolve',
      (tester) async {
    // A user who leaves the prompt sitting must not cost us the attribution.
    final order = <String>[];
    final tracking = _RecordingTrackingAuthorizationService(
      order,
      delay: const Duration(milliseconds: 50),
    );
    final attribution = _RecordingInstallAttributionService(order);

    await tester.pumpWidget(
      PawVaultApp(
        dependencies: AppDependencies.localFirst(
          trackingAuthorizationService: tracking,
          installAttributionService: attribution,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(order, ['att', 'attribution']);
  });
}

class _RecordingTrackingAuthorizationService
    implements TrackingAuthorizationService {
  _RecordingTrackingAuthorizationService(this._order, {this.delay});

  final List<String> _order;
  final Duration? delay;
  int callCount = 0;

  @override
  Future<void> requestAuthorization() async {
    callCount++;
    final wait = delay;
    if (wait != null) {
      await Future<void>.delayed(wait);
    }
    _order.add('att');
  }
}

class _RecordingInstallAttributionService implements InstallAttributionService {
  _RecordingInstallAttributionService(this._order);

  final List<String> _order;
  int callCount = 0;

  @override
  Future<void> enableCollection() async {
    callCount++;
    _order.add('attribution');
  }
}
