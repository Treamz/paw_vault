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
}
