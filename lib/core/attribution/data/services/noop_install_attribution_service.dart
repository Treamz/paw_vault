import 'package:paw_vault/core/attribution/domain/services/install_attribution_service.dart';

/// [InstallAttributionService] that collects nothing.
///
/// Used in local-first mode and whenever RevenueCat is unconfigured (no SDK
/// key): there is no backend to report an install to, so collecting a token
/// would be pointless rather than merely idle.
class NoopInstallAttributionService implements InstallAttributionService {
  const NoopInstallAttributionService();

  @override
  Future<void> enableCollection() async {}
}
