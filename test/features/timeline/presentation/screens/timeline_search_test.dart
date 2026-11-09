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

/// Searching the timeline from the screen.
void main() {
  group('TimelineScreen search', () {
    testWidgets('narrows the list as a query is typed', (tester) async {
      await tester.pumpWidget(_app(_events));
      await tester.pumpAndSettle();

      expect(find.text('Rabies booster'), findsOneWidget);
      expect(find.text('Limping'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'rabies');
      await tester.pumpAndSettle();

      expect(find.text('Rabies booster'), findsOneWidget);
      expect(find.text('Limping'), findsNothing);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();

      expect(find.text('Limping'), findsOneWidget);
    });

    testWidgets('finds an event by its description', (tester) async {
      await tester.pumpWidget(_app(_events));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'left front paw');
      await tester.pumpAndSettle();

      expect(find.text('Limping'), findsOneWidget);
      expect(find.text('Rabies booster'), findsNothing);
    });

    testWidgets(
        'a search that matches nothing does not claim the timeline '
        'is empty', (tester) async {
      await tester.pumpWidget(_app(_events));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('Nothing found'), findsOneWidget);
      // The message these two used to share is the bug this guards against:
      // it told someone who had mistyped that they had recorded nothing.
      expect(find.text('No events yet'), findsNothing);
    });

    testWidgets('an empty timeline has nothing to search, and says only that',
        (tester) async {
      await tester.pumpWidget(_app(const []));
      await tester.pumpAndSettle();

      expect(find.text('No events yet'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });
}

final _events = [
  PetEvent(
    id: const EntityId('event-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    title: 'Rabies booster',
    type: PetEventType.vaccination,
    date: UtcDateTime(DateTime.utc(2026, 5, 4)),
    source: PetEventSource.manual,
  ),
  PetEvent(
    id: const EntityId('event-2'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    title: 'Limping',
    type: PetEventType.symptom,
    description: 'On the left front paw after the walk',
    date: UtcDateTime(DateTime.utc(2026, 5, 6)),
    source: PetEventSource.manual,
  ),
];

Widget _app(List<PetEvent> events) {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: _FakeAuthRepository()),
      RepositoryProvider<TimelineRepository>.value(
        value: _FakeTimelineRepository(events),
      ),
    ],
    child: const MaterialApp(home: TimelineScreen(petId: 'pet-1')),
  );
}

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
  _FakeTimelineRepository(this.events);

  final List<PetEvent> events;

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PetEvent>> watchEvents({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream.value(events);

  @override
  Future<PetEvent?> getEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async {
    for (final event in events) {
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
