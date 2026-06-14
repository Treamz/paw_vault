import 'package:paw_vault/core/subscription/domain/services/paywall_presenter.dart';

/// [PaywallPresenter] for local-first mode. There is no store, and the no-op
/// subscription service grants full access, so the paywall is never presented.
class NoopPaywallPresenter implements PaywallPresenter {
  const NoopPaywallPresenter();

  @override
  Future<PaywallOutcome> presentIfNeeded() async => PaywallOutcome.notPresented;
}
