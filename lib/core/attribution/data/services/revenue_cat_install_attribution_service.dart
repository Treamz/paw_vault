import 'package:paw_vault/core/attribution/domain/services/install_attribution_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// [InstallAttributionService] backed by RevenueCat.
///
/// RevenueCat does the whole job natively: it reads the AdServices token off
/// the main thread, posts it once per install (persisting the "already sent"
/// flag and rolling it back if the post fails), re-attempts on every
/// foreground, and resolves the token to campaign data server-side. So this is
/// a single opt-in call — the collection is **not** enabled by
/// `Purchases.configure`.
///
/// Requires `Purchases.configure(...)` to have run first, which is why this is
/// injected from `AppBootstrap` rather than constructed in `AppDependencies`.
///
/// On Android the plugin call is a documented no-op, and on iOS below 14.3 the
/// native plugin logs a warning, so no platform check is needed here.
class RevenueCatInstallAttributionService implements InstallAttributionService {
  const RevenueCatInstallAttributionService();

  @override
  Future<void> enableCollection() =>
      Purchases.enableAdServicesAttributionTokenCollection();
}
