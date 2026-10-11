import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/presentation/widgets/paw_attention_badge.dart';

Future<Color> _badgeBackground(
  WidgetTester tester,
  PawAttentionLevel level, {
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(body: PawAttentionBadge(level: level)),
    ),
  );
  await tester.pumpAndSettle();
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(PawAttentionBadge),
      matching: find.byType(Container),
    ),
  );
  return (container.decoration! as BoxDecoration).color!;
}

/// Rough hue test: is this colour more green than red, or the reverse?
bool _readsGreen(Color c) => c.g > c.r;
bool _readsRed(Color c) => c.r > c.g && c.r > c.b;
bool _readsGrey(Color c) =>
    (c.r - c.g).abs() < 0.04 && (c.g - c.b).abs() < 0.04;

void main() {
  group('PawAttentionBadge colours', () {
    testWidgets('"nothing stood out" reads green, not grey', (tester) async {
      // QA: grey read as "could not assess" rather than "this scan found
      // nothing notable" — and it was the same grey as the undetermined
      // level, so the two outcomes were indistinguishable.
      final colour =
          await _badgeBackground(tester, PawAttentionLevel.nothingNotable);
      expect(_readsGreen(colour), isTrue, reason: '$colour should be green');
      expect(_readsGrey(colour), isFalse);
    });

    testWidgets('"worth showing a vet soon" reads red, not blue',
        (tester) async {
      // QA: the blue read as positive and drew no attention.
      final colour = await _badgeBackground(tester, PawAttentionLevel.vetSoon);
      expect(_readsRed(colour), isTrue, reason: '$colour should be red');
    });

    testWidgets('"no result" stays grey', (tester) async {
      // The one level that really does mean "could not assess" keeps the
      // neutral colour, so it cannot be confused with a clean scan.
      final colour =
          await _badgeBackground(tester, PawAttentionLevel.undetermined);
      expect(_readsGrey(colour), isTrue, reason: '$colour should be grey');
    });

    testWidgets('the two outcomes are not the same colour', (tester) async {
      final clean =
          await _badgeBackground(tester, PawAttentionLevel.nothingNotable);
      final unknown =
          await _badgeBackground(tester, PawAttentionLevel.undetermined);
      expect(clean, isNot(unknown));
    });

    testWidgets('the green and red survive dark mode', (tester) async {
      final clean = await _badgeBackground(
        tester,
        PawAttentionLevel.nothingNotable,
        brightness: Brightness.dark,
      );
      final vet = await _badgeBackground(
        tester,
        PawAttentionLevel.vetSoon,
        brightness: Brightness.dark,
      );
      expect(_readsGreen(clean), isTrue, reason: '$clean should be green');
      expect(_readsRed(vet), isTrue, reason: '$vet should be red');
    });
  });
}
