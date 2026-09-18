/// How much attention the photographed paw appears to warrant.
///
/// Deliberately non-diagnostic: these levels describe *what to do next*, never
/// what is wrong. PawVault does not diagnose and is not a substitute for a
/// veterinarian, so there is no "healthy" or "fine" level — the mildest level
/// says only that nothing stood out in one photograph.
enum PawAttentionLevel {
  /// Nothing stood out in the photo. Not a clean bill of health.
  nothingNotable,

  /// Something is visible that is worth watching over the next few days.
  monitor,

  /// Worth showing to a veterinarian at the next opportunity.
  vetSoon,

  /// Worth contacting a veterinarian promptly.
  vetPromptly,

  /// No level could be established — an unusable photo, an unparseable model
  /// reply, or a failure. Never treated as reassurance.
  undetermined,
}

/// Ordering used to compare severity. [PawAttentionLevel.undetermined] sits
/// below every established level so that raising from it always wins.
extension PawAttentionLevelSeverity on PawAttentionLevel {
  int get severity => switch (this) {
        PawAttentionLevel.undetermined => 0,
        PawAttentionLevel.nothingNotable => 1,
        PawAttentionLevel.monitor => 2,
        PawAttentionLevel.vetSoon => 3,
        PawAttentionLevel.vetPromptly => 4,
      };

  /// Returns whichever of the two levels warrants more attention.
  ///
  /// Used by the safety filter, which may only ever escalate: if the model
  /// said something notable, suppressing its wording must not suppress the
  /// signal.
  PawAttentionLevel raisedTo(PawAttentionLevel other) =>
      other.severity > severity ? other : this;

  bool get suggestsVet =>
      this == PawAttentionLevel.vetSoon ||
      this == PawAttentionLevel.vetPromptly;
}
