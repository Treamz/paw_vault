/// Enables collection of the platform's install-attribution signal, so an
/// install that followed an Apple Search Ads click can be credited to the
/// campaign that produced it.
///
/// On iOS that signal is Apple's AdServices attribution token (iOS 14.3+).
/// **The token never crosses into Dart.** Implementations ask the underlying
/// SDK to collect and resolve it natively, and only campaign-level fields
/// (campaign, ad group, keyword) ever reach a reporting backend — those are
/// shared by every install from the same ad, so they identify an advert rather
/// than a person. `docs/ANALYTICS.md` forbids sending identifiers, and keeping
/// the token out of Dart makes that structural instead of a promise.
///
/// Implementations are safe to call once per launch: the SDK reports at most
/// once per install and retries on its own when Apple is not yet ready.
///
/// See `docs/ASA.md`.
abstract interface class InstallAttributionService {
  Future<void> enableCollection();
}
