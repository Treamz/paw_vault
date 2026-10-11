import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/presentation/widgets/adaptive_layout.dart';

void main() {
  group('hasRoomForTwoPanes', () {
    test('a phone gets one pane, held either way up', () {
      expect(hasRoomForTwoPanes(const Size(440, 956)), isFalse);

      // The case a width test on its own would get wrong: a Pro Max on its
      // side is wide enough for two panes and far too short for them.
      expect(hasRoomForTwoPanes(const Size(956, 440)), isFalse);
    });

    test('a folded iPhone Duo gets one pane', () {
      // The case a shortest-side test on its own would get wrong: this is
      // square enough to read as a tablet while being 466 across.
      expect(hasRoomForTwoPanes(const Size(466, 678)), isFalse);
    });

    test('an unfolded iPhone Duo gets two', () {
      expect(hasRoomForTwoPanes(const Size(951, 669)), isTrue);
    });

    test('an iPad gets two, held either way up', () {
      expect(hasRoomForTwoPanes(const Size(1024, 1366)), isTrue);
      expect(hasRoomForTwoPanes(const Size(1366, 1024)), isTrue);
    });
  });
}
