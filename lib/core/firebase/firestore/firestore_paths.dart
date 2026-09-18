abstract final class FirestorePaths {
  static String user(String userId) => 'users/$userId';

  static String pets(String userId) => '${user(userId)}/pets';

  static String pet({
    required String userId,
    required String petId,
  }) {
    return '${pets(userId)}/$petId';
  }

  static String events({
    required String userId,
    required String petId,
  }) {
    return '${pet(userId: userId, petId: petId)}/events';
  }

  static String documents({
    required String userId,
    required String petId,
  }) {
    return '${pet(userId: userId, petId: petId)}/documents';
  }

  static String pawChecks({
    required String userId,
    required String petId,
  }) {
    return '${pet(userId: userId, petId: petId)}/pawChecks';
  }

  static String reminders({
    required String userId,
    required String petId,
  }) {
    return '${pet(userId: userId, petId: petId)}/reminders';
  }

  static String smartMessages({
    required String userId,
    required String petId,
  }) {
    return '${pet(userId: userId, petId: petId)}/smartMessages';
  }

  static String vetSummaryExports({
    required String userId,
    required String petId,
  }) {
    return '${pet(userId: userId, petId: petId)}/vetSummaryExports';
  }

  static String weightEntries({
    required String userId,
    required String petId,
  }) {
    return '${pet(userId: userId, petId: petId)}/weightEntries';
  }

  /// Every collection stored under a single pet.
  ///
  /// This is the one declared source of that set. Account deletion and any
  /// future per-pet cleanup read it instead of listing collections by hand —
  /// a hand-written list goes stale the first time a feature adds a
  /// collection, and the failure is silent: the data simply survives a
  /// deletion the user asked for.
  ///
  /// **Add new per-pet collections here.** A test asserts this covers every
  /// per-pet collection builder declared in this file.
  static List<String> petSubcollections({
    required String userId,
    required String petId,
  }) {
    return [
      events(userId: userId, petId: petId),
      documents(userId: userId, petId: petId),
      pawChecks(userId: userId, petId: petId),
      reminders(userId: userId, petId: petId),
      smartMessages(userId: userId, petId: petId),
      vetSummaryExports(userId: userId, petId: petId),
      weightEntries(userId: userId, petId: petId),
    ];
  }
}
