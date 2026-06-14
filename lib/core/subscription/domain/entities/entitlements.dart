/// The user's current premium ("PawVault Pro") entitlement state.
class Entitlements {
  const Entitlements({
    this.isPro = false,
    this.activeUntil,
    this.willRenew = false,
  });

  /// No active entitlement (free tier).
  static const Entitlements free = Entitlements();

  /// Full access (used by the local-first no-op build, which has no store).
  static const Entitlements unlocked = Entitlements(isPro: true);

  final bool isPro;
  final DateTime? activeUntil;
  final bool willRenew;

  @override
  bool operator ==(Object other) =>
      other is Entitlements &&
      other.isPro == isPro &&
      other.activeUntil == activeUntil &&
      other.willRenew == willRenew;

  @override
  int get hashCode => Object.hash(isPro, activeUntil, willRenew);
}
