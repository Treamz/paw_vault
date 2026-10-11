import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/timeline/presentation/screens/timeline_screen.dart';

/// The event list beside the event it selects, which the app shows on a
/// surface big enough for both. See `hasRoomForTwoPanes`.
void main() {
  const duoUnfolded = Size(951, 669);
  const phone = Size(440, 956);

  Future<void> pumpAt(WidgetTester tester, Size surface) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
  }

  Finder inDetails(String text) => find.descendant(
        of: find.byType(EventDetailsView),
        matching: find.text(text),
      );

  group('TimelineScreen on a wide surface', () {
    testWidgets('reads an event beside the list, with nothing tapped', (
      tester,
    ) async {
      await pumpAt(tester, duoUnfolded);

      expect(find.byType(EventDetailsView), findsOneWidget);
    });

    testWidgets('swaps the pane without covering the list', (tester) async {
      await pumpAt(tester, duoUnfolded);

      await tester.tap(find.byKey(const ValueKey('event-event-2')));
      await tester.pumpAndSettle();

      expect(inDetails('Annual booster'), findsOneWidget);
      // The whole point of the pane: the list it was picked from stays put,
      // where a sheet would have covered it.
      expect(find.byKey(const ValueKey('event-event-1')), findsOneWidget);
    });
  });

  group('TimelineScreen on a phone', () {
    testWidgets('shows no pane, so a tap still opens the sheet', (
      tester,
    ) async {
      await pumpAt(tester, phone);

      // Only the absence is asserted here. Opening the sheet goes through
      // `context.router`, which this harness has no AutoRouter for, and that
      // is the screen's own arrangement rather than anything to do with
      // panes.
      expect(find.byType(EventDetailsView), findsNothing);
      expect(find.byKey(const ValueKey('event-event-1')), findsOneWidget);
    });
  });
}

Widget _app() {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: _FakeAuthRepository()),
      RepositoryProvider<TimelineRepository>.value(
        value: _FakeTimelineRepository(),
      ),
    ],
    child: const MaterialApp(home: TimelineScreen(petId: 'pet-1')),
  );
}

PetEvent _event(String id, String title, int day) => PetEvent(
      id: EntityId(id),
      userId: const EntityId('user-1'),
      petId: const EntityId('pet-1'),
      title: title,
      type: PetEventType.vaccination,
      date: UtcDateTime(DateTime.utc(2026, 5, day)),
      source: PetEventSource.manual,
    );

class _FakeAuthRepository implements AuthRepository {
  static const _user = AppUser(id: 'user-1', isAnonymous: true);

  @override
  Future<AppUser?> currentUser() async => _user;

  @override
  Future<AppUser> signInAnonymously() async => _user;

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() => Stream<AppUser?>.value(_user);
}

class _FakeTimelineRepository implements TimelineRepository {
  final _events = [
    _event('event-1', 'Rabies shot', 2),
    _event('event-2', 'Annual booster', 1),
  ];

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PetEvent>> watchEvents({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream.value(_events);

  @override
  Future<PetEvent?> getEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async {
    for (final event in _events) {
      if (event.id == eventId) return event;
    }
    return null;
  }

  @override
  Future<void> saveEvent(PetEvent event) async {}

  @override
  Future<void> deleteEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async {}
}
