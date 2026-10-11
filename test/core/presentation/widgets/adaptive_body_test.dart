import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/presentation/widgets/adaptive_body.dart';

void main() {
  const content = Key('content');
  final finder = find.byKey(content);

  Future<void> pumpAt(
    WidgetTester tester,
    Size surface, {
    FakeViewPadding? padding,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    if (padding != null) tester.view.padding = padding;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdaptiveBody(child: SizedBox.expand(key: content)),
        ),
      ),
    );
  }

  group('AdaptiveBody', () {
    testWidgets('leaves a phone untouched', (tester) async {
      // The widest iPhone is around 440 logical pixels, so the cap must never
      // bind there: a phone has to render exactly what it rendered before.
      await pumpAt(tester, const Size(440, 956));

      expect(tester.getSize(finder).width, 440);
    });

    testWidgets('caps the content on an unfolded iPhone Duo', (tester) async {
      // 951 across is where a row became an icon on the far left and a
      // chevron most of a screen away.
      await pumpAt(tester, const Size(951, 669));

      expect(tester.getSize(finder).width, AdaptiveBody.defaultMaxWidth);
    });

    testWidgets('caps the content on an iPad', (tester) async {
      await pumpAt(tester, const Size(1024, 1366));

      expect(tester.getSize(finder).width, AdaptiveBody.defaultMaxWidth);
    });

    testWidgets('centres what it caps', (tester) async {
      await pumpAt(tester, const Size(951, 669));

      final box = tester.getRect(finder);
      expect(
        box.left,
        moreOrLessEquals(951 - box.right, epsilon: 0.5),
        reason: 'the margins either side must match',
      );
    });

    testWidgets('keeps the safe area, which Duo is the first to need', (
      tester,
    ) async {
      // Duo's status bar is a vertical strip down the right edge, so this is
      // the first device where a horizontal inset is not zero. Without the
      // SafeArea the first field on a form ran underneath the clock.
      await pumpAt(
        tester,
        const Size(951, 669),
        padding: const FakeViewPadding(right: 80),
      );

      expect(tester.getRect(finder).right, lessThan(951 - 80));
    });
  });
}
