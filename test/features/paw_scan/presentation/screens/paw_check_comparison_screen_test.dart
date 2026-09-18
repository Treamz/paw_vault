import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';
import 'package:paw_vault/features/paw_scan/domain/paw_scan_copy.dart';
import 'package:paw_vault/features/paw_scan/presentation/screens/paw_check_comparison_screen.dart';

PawCheck _check({
  required String id,
  required DateTime checkedAt,
  PawLocation location = PawLocation.frontLeft,
  PawAttentionLevel attentionLevel = PawAttentionLevel.monitor,
  List<String> observations = const ['A dark area on the pad.'],
}) {
  return PawCheck(
    id: EntityId(id),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    location: location,
    attentionLevel: attentionLevel,
    checkedAt: UtcDateTime(checkedAt),
    observations: observations,
    status: PawCheckStatus.confirmed,
  );
}

Widget _app({required PawCheck earlier, required PawCheck later}) {
  return MaterialApp(
    home: PawCheckComparisonScreen(earlier: earlier, later: later),
  );
}

void main() {
  testWidgets('shows both checks with their dates and levels', (tester) async {
    await tester.pumpWidget(
      _app(
        earlier: _check(id: 'a', checkedAt: DateTime.utc(2026, 9, 6)),
        later: _check(
          id: 'b',
          checkedAt: DateTime.utc(2026, 9, 18),
          attentionLevel: PawAttentionLevel.vetSoon,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Earlier'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(find.text('Keep an eye on it'), findsOneWidget);
    expect(find.text('Worth showing a vet soon'), findsOneWidget);
  });

  testWidgets('states how far apart the checks are', (tester) async {
    await tester.pumpWidget(
      _app(
        earlier: _check(id: 'a', checkedAt: DateTime.utc(2026, 9, 6)),
        later: _check(id: 'b', checkedAt: DateTime.utc(2026, 9, 18)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('12 days apart'), findsOneWidget);
  });

  testWidgets('says so when both checks are from the same day', (tester) async {
    await tester.pumpWidget(
      _app(
        earlier: _check(id: 'a', checkedAt: DateTime.utc(2026, 9, 18, 9)),
        later: _check(id: 'b', checkedAt: DateTime.utc(2026, 9, 18, 17)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Both checks are from the same day.'), findsOneWidget);
  });

  testWidgets('warns when the two checks are different paws', (tester) async {
    // Comparing a front paw against a rear one would read as change over time
    // when it is really two different things.
    await tester.pumpWidget(
      _app(
        // The fixture defaults to the front left paw.
        earlier: _check(id: 'a', checkedAt: DateTime.utc(2026, 9, 6)),
        later: _check(
          id: 'b',
          checkedAt: DateTime.utc(2026, 9, 18),
          location: PawLocation.rearRight,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('different paws, so they may not be comparable'),
      findsOneWidget,
    );
  });

  testWidgets('does not warn when both checks are the same paw',
      (tester) async {
    await tester.pumpWidget(
      _app(
        earlier: _check(id: 'a', checkedAt: DateTime.utc(2026, 9, 6)),
        later: _check(id: 'b', checkedAt: DateTime.utc(2026, 9, 18)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('different paws'), findsNothing);
  });

  testWidgets('carries the disclaimer, since this is the vet-facing screen',
      (tester) async {
    await tester.pumpWidget(
      _app(
        earlier: _check(id: 'a', checkedAt: DateTime.utc(2026, 9, 6)),
        later: _check(id: 'b', checkedAt: DateTime.utc(2026, 9, 18)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(PawScanCopy.disclaimerTitle), findsOneWidget);
  });
}
