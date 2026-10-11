import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';
import 'package:paw_vault/features/paw_scan/presentation/screens/paw_check_detail_screen.dart';

PawCheck _check({
  List<Uri> photoUrls = const [],
  List<String> observations = const ['A dark area near the centre of the pad.'],
  String? summary,
  String? ownerNote,
  bool includeInVetSummary = false,
}) {
  return PawCheck(
    id: const EntityId('check-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    location: PawLocation.frontLeft,
    attentionLevel: PawAttentionLevel.monitor,
    checkedAt: UtcDateTime(DateTime.utc(2026, 9, 18, 14, 30)),
    photoUrls: photoUrls,
    observations: observations,
    summary: summary,
    ownerNote: ownerNote,
    includeInVetSummary: includeInVetSummary,
    confidence: 0.9,
    status: PawCheckStatus.confirmed,
  );
}

Widget _app(PawCheck check) {
  return MaterialApp(home: PawCheckDetailScreen(check: check));
}

/// A phone-tall surface. The photos are 240 high, so at the default 800x600
/// the second one is never built and a finder for it would miss for the wrong
/// reason.
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('PawCheckDetailScreen', () {
    testWidgets('shows the photos a saved check was made from', (tester) async {
      // QA: History only listed its checks, so the photos — the thing an
      // owner would show a vet — could not be seen again once saved.
      _useTallSurface(tester);
      await tester.pumpWidget(
        _app(
          _check(
            photoUrls: [
              Uri.parse('https://example.com/paw_1.jpg'),
              Uri.parse('https://example.com/paw_2.jpg'),
            ],
          ),
        ),
      );
      // Not pumpAndSettle: the loading placeholder is a progress indicator,
      // which never settles.
      await tester.pump();

      expect(find.byType(CachedNetworkImage), findsNWidgets(2));
      expect(find.text('Photos'), findsOneWidget);
    });

    testWidgets('shows every observation, the summary and the owner note',
        (tester) async {
      await tester.pumpWidget(
        _app(
          _check(
            observations: const [
              'A dark area near the centre of the pad.',
              'Some redness between the toes.',
            ],
            summary: 'Two things worth another look.',
            ownerNote: 'She has been licking it.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('A dark area near the centre of the pad.'),
        findsOneWidget,
      );
      expect(find.text('Some redness between the toes.'), findsOneWidget);
      expect(find.text('Two things worth another look.'), findsOneWidget);

      // Last on a scrolling screen, so reach it rather than relying on it
      // fitting: the content column is capped on a wide surface, which makes
      // it taller than the test viewport.
      final note = find.text('She has been licking it.');
      await tester.scrollUntilVisible(note, 200);
      expect(note, findsOneWidget);
    });

    testWidgets('carries the date, the paw and the attention level',
        (tester) async {
      await tester.pumpWidget(_app(_check()));
      await tester.pumpAndSettle();

      expect(find.textContaining('September 18, 2026'), findsOneWidget);
      expect(find.text('Front left'), findsOneWidget);
      expect(find.text('Keep an eye on it'), findsOneWidget);
    });

    testWidgets('says whether the check is in the vet summary', (tester) async {
      await tester.pumpWidget(_app(_check(includeInVetSummary: true)));
      await tester.pumpAndSettle();
      expect(find.text('Included in the vet summary'), findsOneWidget);

      await tester.pumpWidget(_app(_check()));
      await tester.pumpAndSettle();
      expect(find.text('Not included in the vet summary'), findsOneWidget);
    });

    testWidgets('keeps the disclaimer, as every Paw Scan surface does',
        (tester) async {
      await tester.pumpWidget(_app(_check()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Paw Scan describes'), findsOneWidget);
    });
  });
}
