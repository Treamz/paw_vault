/// Permanently deletes the signed-in user's account and all data associated
/// with it. Required by App Store Guideline 5.1.1(v): an app that supports
/// account creation must let the user initiate and complete deletion in-app.
abstract interface class AccountDeletionService {
  Future<void> deleteAccount();
}

/// Thrown when the provider requires the user to have signed in recently before
/// the account can be deleted. The UI should ask the user to sign in again and
/// retry, which always completes the deletion in-app.
class ReauthenticationRequiredException implements Exception {
  const ReauthenticationRequiredException();

  @override
  String toString() => 'ReauthenticationRequiredException';
}
