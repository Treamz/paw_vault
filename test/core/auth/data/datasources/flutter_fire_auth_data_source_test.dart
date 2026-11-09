import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/data/datasources/flutter_fire_auth_data_source.dart';

/// Which Firebase Auth failures end a cached session.
///
/// The data source around this needs a real [FirebaseAuth] and is not unit
/// tested; this is the decision inside it, and the one worth pinning.
void main() {
  group('isTerminalAuthErrorCode', () {
    test('a session whose account is gone or barred cannot be saved', () {
      // What put the app in the state this guards against: an anonymous
      // account that no longer existed server-side, while the device still
      // held it and signed every Firestore read with it.
      expect(isTerminalAuthErrorCode('user-not-found'), isTrue);
      expect(isTerminalAuthErrorCode('user-disabled'), isTrue);
      expect(isTerminalAuthErrorCode('user-token-expired'), isTrue);
      expect(isTerminalAuthErrorCode('invalid-user-token'), isTrue);
    });

    test('being offline does not end a session', () {
      // The one that must never be terminal. Treating it as terminal would
      // sign the owner out and into a new, empty account every time the app
      // opened without a connection -- their archive would simply be gone
      // from the screen.
      expect(isTerminalAuthErrorCode('network-request-failed'), isFalse);
      expect(isTerminalAuthErrorCode('too-many-requests'), isFalse);
    });

    test('an unrecognised code is not treated as terminal', () {
      // Unknown means unknown. A new or misread code must not cost someone
      // their session.
      expect(isTerminalAuthErrorCode('something-new-from-firebase'), isFalse);
      expect(isTerminalAuthErrorCode(''), isFalse);
    });
  });
}
