import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/subscription/data/services/noop_paywall_presenter.dart';
import 'package:paw_vault/core/subscription/domain/services/paywall_presenter.dart';

void main() {
  test('NoopPaywallPresenter never presents a paywall', () async {
    const presenter = NoopPaywallPresenter();
    expect(await presenter.presentIfNeeded(), PaywallOutcome.notPresented);
  });
}
