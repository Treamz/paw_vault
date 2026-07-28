// Drives the real app through QA batch 4's visible changes: editable owner
// information, the timeline event detail sheet with a separate Edit button,
// reminder complete/un-complete from the list, and the document form's
// photo/file attach options + inline validation errors. Run with the
// screenshot driver:
//
//   SCREENSHOT_DIR=build/verify_screenshots flutter drive \
//     --driver=test_driver/screenshots.dart \
//     --target=integration_test/qa_batch4_test.dart \
//     -d <simulator-udid>
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';

import 'support/fakes.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('owner info, event details, reminder toggle, document attach',
      (tester) async {
    final pets = _FakePetRepository(const [
      Pet(
        id: EntityId('pet-1'),
        userId: EntityId('user-1'),
        name: 'Rex',
      ),
    ]);
    final timeline = _MemoryTimelineRepository([
      PetEvent(
        id: const EntityId('event-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        type: PetEventType.vaccination,
        title: 'Rabies shot',
        description: 'Annual rabies vaccination at GoodVet clinic.',
        date: UtcDateTime(DateTime(2026, 7, 15)),
        source: PetEventSource.manual,
      ),
    ]);
    final reminders = _MemoryReminderRepository([
      Reminder(
        id: const EntityId('reminder-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        title: 'Deworming due',
        dateTime: UtcDateTime(DateTime(2027, 1, 15, 9)),
      ),
    ]);
    final base = AppDependencies.localFirst();
    final dependencies = AppDependencies(
      authRepository: FakeAuthRepository(),
      storageRepository: base.storageRepository,
      petRepository: pets,
      timelineRepository: timeline,
      documentRepository: base.documentRepository,
      reminderRepository: reminders,
      aiRepository: base.aiRepository,
      smartInputRepository: base.smartInputRepository,
      vetSummaryExportRepository: base.vetSummaryExportRepository,
      filePicker: base.filePicker,
      documentFileOpener: base.documentFileOpener,
      documentExtractionAiRepository: base.documentExtractionAiRepository,
      documentSourcePicker: base.documentSourcePicker,
      petPhotoPicker: base.petPhotoPicker,
      eventPhotoPicker: base.eventPhotoPicker,
      reminderNotificationScheduler: base.reminderNotificationScheduler,
      analyticsService: base.analyticsService,
      subscriptionService: base.subscriptionService,
      paywallPresenter: base.paywallPresenter,
      trackingAuthorizationService: base.trackingAuthorizationService,
      accountDeletionService: base.accountDeletionService,
    );

    await tester.pumpWidget(PawVaultApp(dependencies: dependencies));
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    // --- Owner information: editable from the profile.
    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    expect(find.text('Owner Information'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit owner information'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Name'),
      'Emma Watson',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Phone'),
      '+34 600 123 456',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Emma Watson'), findsOneWidget);
    expect(find.text('+34 600 123 456'), findsOneWidget);
    expect(find.text('emma@example.com'), findsOneWidget);
    await binding.takeScreenshot('01_owner_info_saved');

    // --- Timeline: tapping an event opens details with an Edit button.
    final timelineTile = find.text('Timeline');
    await tester.ensureVisible(timelineTile);
    await tester.tap(timelineTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rabies shot'));
    await tester.pumpAndSettle();
    expect(
      find.text('Annual rabies vaccination at GoodVet clinic.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Edit event'), findsOneWidget);
    await binding.takeScreenshot('02_event_detail_sheet');
    // Close the sheet.
    await tester.tapAt(const Offset(20, 60));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // --- Reminders: complete and un-complete from the list checkbox.
    final remindersTile = find.text('Reminders');
    await tester.ensureVisible(remindersTile);
    await tester.tap(remindersTile);
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(reminders.reminders.single.isCompleted, isTrue);
    await binding.takeScreenshot('03_reminder_completed');
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(reminders.reminders.single.isCompleted, isFalse);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // --- Documents: attach options + inline validation errors.
    final documentsTile = find.text('Documents');
    await tester.ensureVisible(documentsTile);
    await tester.tap(documentsTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add document'));
    await tester.pumpAndSettle();
    final attach = find.text('Attach photo or file (optional)');
    await tester.ensureVisible(attach);
    await tester.tap(attach);
    await tester.pumpAndSettle();
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('Choose a file'), findsOneWidget);
    await binding.takeScreenshot('04_document_attach_options');
    await tester.tapAt(const Offset(20, 60));
    await tester.pumpAndSettle();

    // Saving with empty required fields highlights them inline.
    final save = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Document type is required'), findsOneWidget);
    expect(find.text('Document title is required'), findsOneWidget);
    await binding.takeScreenshot('05_document_validation_errors');
  });
}

class _MemoryTimelineRepository implements TimelineRepository {
  _MemoryTimelineRepository(List<PetEvent> seed) : _events = List.of(seed);

  final List<PetEvent> _events;
  final _controller = StreamController<List<PetEvent>>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PetEvent>> watchEvents({
    required EntityId userId,
    required EntityId petId,
  }) async* {
    yield List.of(_events);
    yield* _controller.stream;
  }

  @override
  Future<PetEvent?> getEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async {
    for (final event in _events) {
      if (event.id == eventId) {
        return event;
      }
    }
    return null;
  }

  @override
  Future<void> saveEvent(PetEvent event) async {
    _events.removeWhere((existing) => existing.id == event.id);
    _events.add(event);
    _controller.add(List.of(_events));
  }

  @override
  Future<void> deleteEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async {
    _events.removeWhere((existing) => existing.id == eventId);
    _controller.add(List.of(_events));
  }
}

class _MemoryReminderRepository implements ReminderRepository {
  _MemoryReminderRepository(List<Reminder> seed) : reminders = List.of(seed);

  final List<Reminder> reminders;
  final _controller = StreamController<List<Reminder>>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<Reminder>> watchReminders({
    required EntityId userId,
    required EntityId petId,
  }) async* {
    yield List.of(reminders);
    yield* _controller.stream;
  }

  @override
  Future<Reminder?> getReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async {
    for (final reminder in reminders) {
      if (reminder.id == reminderId) {
        return reminder;
      }
    }
    return null;
  }

  @override
  Future<void> saveReminder(Reminder reminder) async {
    reminders.removeWhere((existing) => existing.id == reminder.id);
    reminders.add(reminder);
    _controller.add(List.of(reminders));
  }

  @override
  Future<void> completeReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async {
    final index = reminders.indexWhere((reminder) => reminder.id == reminderId);
    if (index == -1) {
      return;
    }
    final current = reminders[index];
    reminders[index] = Reminder(
      id: current.id,
      userId: current.userId,
      petId: current.petId,
      title: current.title,
      description: current.description,
      dateTime: current.dateTime,
      repeatType: current.repeatType,
      relatedEventId: current.relatedEventId,
      isCompleted: true,
      createdAt: current.createdAt,
    );
    _controller.add(List.of(reminders));
  }

  @override
  Future<void> deleteReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async {
    reminders.removeWhere((existing) => existing.id == reminderId);
    _controller.add(List.of(reminders));
  }
}

class _FakePetRepository implements PetRepository {
  _FakePetRepository(this.pets);

  final List<Pet> pets;

  @override
  Future<void> initialize() async {}

  @override
  Future<Pet?> getPet({
    required EntityId userId,
    required EntityId petId,
  }) async {
    for (final pet in pets) {
      if (pet.id == petId) {
        return pet;
      }
    }
    return null;
  }

  @override
  Future<void> savePet(Pet pet) async {}

  @override
  Future<void> deletePet({
    required EntityId userId,
    required EntityId petId,
  }) async {}

  @override
  Stream<List<Pet>> watchPets(EntityId userId) => Stream<List<Pet>>.value(pets);
}
