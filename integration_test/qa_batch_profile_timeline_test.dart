// Drives the real app through this QA batch's visible changes:
// formatted birth date + owner info on the profile, body measurements in the
// pet form and Physical Details, and photo (gallery/camera) attachments on
// timeline events. Run with the screenshot driver:
//
//   SCREENSHOT_DIR=build/verify_screenshots flutter drive \
//     --driver=test_driver/screenshots.dart \
//     --target=integration_test/qa_batch_profile_timeline_test.dart \
//     -d <simulator-udid>
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_measurement.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/timeline/domain/services/event_photo_picker.dart';

import 'support/fakes.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'profile shows owner/birth date/measurements and events '
      'take photo attachments', (tester) async {
    final pngBytes = await _makePng();
    final picker = _FakeEventPhotoPicker(pngBytes);
    final storage = _RecordingStorageRepository();
    final pets = _MemoryPetRepository([
      const Pet(
        id: EntityId('pet-1'),
        userId: EntityId('user-1'),
        name: 'Rex',
        species: 'Dog',
        birthDate: DateOnly(year: 2020, month: 1, day: 5),
        weight: PetWeight(value: 5),
      ),
    ]);
    final timeline = _MemoryTimelineRepository();
    final base = AppDependencies.localFirst();
    final dependencies = AppDependencies(
      authRepository: FakeAuthRepository(),
      storageRepository: storage,
      petRepository: pets,
      timelineRepository: timeline,
      documentRepository: base.documentRepository,
      reminderRepository: base.reminderRepository,
      aiRepository: base.aiRepository,
      smartInputRepository: base.smartInputRepository,
      vetSummaryExportRepository: base.vetSummaryExportRepository,
      filePicker: base.filePicker,
      documentFileOpener: base.documentFileOpener,
      documentExtractionAiRepository: base.documentExtractionAiRepository,
      documentSourcePicker: base.documentSourcePicker,
      petPhotoPicker: base.petPhotoPicker,
      eventPhotoPicker: picker,
      reminderNotificationScheduler: FakeReminderNotificationScheduler(),
      analyticsService: base.analyticsService,
      subscriptionService: base.subscriptionService,
      paywallPresenter: base.paywallPresenter,
      trackingAuthorizationService: base.trackingAuthorizationService,
      accountDeletionService: base.accountDeletionService,
    );

    await tester.pumpWidget(PawVaultApp(dependencies: dependencies));
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    // --- Profile: formatted birth date + owner information card.
    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    expect(find.text('Birth Date'), findsOneWidget);
    expect(find.text('Jan 5, 2020'), findsOneWidget);
    expect(find.text('Owner Information'), findsOneWidget);
    expect(find.text('emma@example.com'), findsOneWidget);
    await binding.takeScreenshot('01_profile_owner_birthdate');

    // --- Edit form: add a body measurement via the dropdown.
    await tester.tap(find.byTooltip('Edit pet'));
    await tester.pumpAndSettle();
    final addMeasurement = find.text('Add measurement');
    await tester.ensureVisible(addMeasurement);
    await tester.tap(addMeasurement);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<PetMeasurementType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Head circumference').last);
    await tester.pumpAndSettle();
    final valueField = find.widgetWithText(TextFormField, 'Value');
    await tester.ensureVisible(valueField);
    await tester.enterText(valueField, '25');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02_measurement_row_form');

    final saveChanges = find.widgetWithText(FilledButton, 'Save Changes');
    await tester.ensureVisible(saveChanges);
    await tester.tap(saveChanges);
    await tester.pumpAndSettle();

    // --- Profile: measurement listed under Physical Details.
    expect(find.text('Physical Details'), findsOneWidget);
    expect(find.text('Head circumference'), findsOneWidget);
    expect(find.text('25 cm'), findsOneWidget);
    await binding.takeScreenshot('03_profile_measurements');

    // --- Timeline: new event with a photo attachment from the gallery.
    final timelineTile = find.text('Timeline');
    await tester.ensureVisible(timelineTile);
    await tester.tap(timelineTile);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add event'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<PetEventType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vaccination').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title *'),
      'Rabies shot',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final dateTile = find.text('Date *');
    await tester.ensureVisible(dateTile);
    await tester.tap(dateTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final galleryButton = find.widgetWithText(OutlinedButton, 'Gallery');
    await tester.ensureVisible(galleryButton);
    await tester.tap(galleryButton);
    await tester.pumpAndSettle();
    expect(picker.lastSource, EventPhotoSource.gallery);
    expect(find.byType(Image), findsOneWidget);
    await binding.takeScreenshot('04_event_photo_attachment');

    final addEvent = find.widgetWithText(FilledButton, 'Add Event');
    await tester.ensureVisible(addEvent);
    await tester.tap(addEvent);
    await tester.pumpAndSettle();

    expect(storage.uploadCallCount, 1);
    expect(
      storage.uploadedPath,
      allOf(
        startsWith('users/user-1/pets/pet-1/events/'),
        contains('/attachments/'),
      ),
    );
    final savedEvent = timeline.savedEvent!;
    expect(savedEvent.attachments, hasLength(1));
    expect(find.text('Rabies shot'), findsOneWidget);
    await binding.takeScreenshot('05_timeline_event_saved');
  });

  testWidgets('an event reminder takes a time as well as a date',
      (tester) async {
    // Asked for by QA: a reminder is for a moment, so a date alone is not
    // enough. nextReminderDate was already a full timestamp; only the form
    // had no way to set the time of day.
    final pets = _MemoryPetRepository([
      const Pet(
        id: EntityId('pet-1'),
        userId: EntityId('user-1'),
        name: 'Rex',
      ),
    ]);
    final timeline = _MemoryTimelineRepository();
    final reminders = FakeReminderRepository();
    final base = AppDependencies.localFirst();
    final dependencies = AppDependencies(
      authRepository: FakeAuthRepository(),
      storageRepository: _RecordingStorageRepository(),
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
      eventPhotoPicker: _FakeEventPhotoPicker(await _makePng()),
      reminderNotificationScheduler: FakeReminderNotificationScheduler(),
      analyticsService: base.analyticsService,
      subscriptionService: base.subscriptionService,
      paywallPresenter: base.paywallPresenter,
      trackingAuthorizationService: base.trackingAuthorizationService,
      accountDeletionService: base.accountDeletionService,
    );

    await tester.pumpWidget(PawVaultApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    final timelineTile = find.text('Timeline');
    await tester.ensureVisible(timelineTile);
    await tester.tap(timelineTile);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add event'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<PetEventType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vaccination').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title *'),
      'Booster due',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final dateTile = find.text('Date *');
    await tester.ensureVisible(dateTile);
    await tester.tap(dateTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // QA hit this with the title focused: the keyboard stayed over the
    // calendar, which squeezed the dialog and left the selected day's circle
    // cramped and off-centre.
    //
    // This pins the invariant rather than guarding the fix: `tester.tap`
    // releases focus from a text field where iOS does not, so removing the
    // screen's own unfocus call still leaves this passing. Verified by
    // removing it and re-running. It would still catch code that actively
    // put focus back.
    // Scrolled back into view first: the tap above moves the form, and on a
    // short screen -- an unfolded iPhone Duo is 669pt tall against an iPhone
    // 17's 852 -- that leaves this field off screen, so the tap misses and
    // nothing takes focus. The assertion below is unchanged.
    final titleField = find.widgetWithText(TextFormField, 'Title *');
    await tester.ensureVisible(titleField);
    await tester.pumpAndSettle();
    await tester.tap(titleField);
    await tester.pumpAndSettle();
    expect(_focusedEditable(), isNotNull);

    final reminderDate = find.text('Reminder Date');
    await tester.ensureVisible(reminderDate);
    await tester.tap(reminderDate);
    await tester.pumpAndSettle();
    expect(
      _focusedEditable(),
      isNull,
      reason: 'nothing may hold focus once the calendar is open',
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final reminderTime = find.text('Reminder Time');
    expect(reminderTime, findsOneWidget);
    await tester.ensureVisible(reminderTime);
    await tester.tap(reminderTime);
    await tester.pumpAndSettle();

    // The picker opens on the dial; type the time instead, which also
    // exercises the keyboard-entry focus fix.
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final hourField = find
        .descendant(
          of: find.byType(TimePickerDialog),
          matching: find.byType(EditableText),
        )
        .first;
    await tester.enterText(hourField, '14');
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();

    final addEvent = find.widgetWithText(FilledButton, 'Add Event');
    await tester.ensureVisible(addEvent);
    await tester.tap(addEvent);
    await tester.pumpAndSettle();

    final saved = timeline.savedEvent!;
    final remindAt = saved.nextReminderDate!.value.toLocal();
    expect(remindAt.hour, 14, reason: 'the chosen hour must be kept');
    // A date picked on its own lands on a sensible hour, not midnight, which
    // would read as "no time was set".
    expect(remindAt.minute, 0);

    // And the reminder is real: it is saved, linked to the event, and shows
    // up in the Reminders list. The date used to be rendered on the timeline
    // and nowhere else, so nothing ever reminded the owner.
    final reminder = reminders.reminders.single;
    expect(reminder.title, 'Booster due');
    expect(reminder.relatedEventId, saved.id);
    expect(reminder.dateTime.value, saved.nextReminderDate!.value);

    await tester.pageBack();
    await tester.pumpAndSettle();
    final remindersTile = find.text('Reminders');
    await tester.ensureVisible(remindersTile);
    await tester.pumpAndSettle();
    await tester.tap(remindersTile);
    await tester.pumpAndSettle();
    expect(find.text('Booster due'), findsOneWidget);
  });

  testWidgets('saving an event with the title focused dismisses the keyboard',
      (tester) async {
    // Reported by QA: the Timeline keyboard sometimes stayed up, survived the
    // way back to the main menu, and only went away by killing the app. It is
    // the only form that pops itself from a BlocListener on save, so it can
    // leave the route while a field still holds focus.
    final picker = _FakeEventPhotoPicker(await _makePng());
    final pets = _MemoryPetRepository([
      const Pet(
        id: EntityId('pet-1'),
        userId: EntityId('user-1'),
        name: 'Rex',
      ),
    ]);
    final timeline = _MemoryTimelineRepository();
    final base = AppDependencies.localFirst();
    final dependencies = AppDependencies(
      authRepository: FakeAuthRepository(),
      storageRepository: _RecordingStorageRepository(),
      petRepository: pets,
      timelineRepository: timeline,
      documentRepository: base.documentRepository,
      reminderRepository: base.reminderRepository,
      aiRepository: base.aiRepository,
      smartInputRepository: base.smartInputRepository,
      vetSummaryExportRepository: base.vetSummaryExportRepository,
      filePicker: base.filePicker,
      documentFileOpener: base.documentFileOpener,
      documentExtractionAiRepository: base.documentExtractionAiRepository,
      documentSourcePicker: base.documentSourcePicker,
      petPhotoPicker: base.petPhotoPicker,
      eventPhotoPicker: picker,
      reminderNotificationScheduler: FakeReminderNotificationScheduler(),
      analyticsService: base.analyticsService,
      subscriptionService: base.subscriptionService,
      paywallPresenter: base.paywallPresenter,
      trackingAuthorizationService: base.trackingAuthorizationService,
      accountDeletionService: base.accountDeletionService,
    );

    await tester.pumpWidget(PawVaultApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    final timelineTile = find.text('Timeline');
    await tester.ensureVisible(timelineTile);
    await tester.tap(timelineTile);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add event'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<PetEventType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vaccination').last);
    await tester.pumpAndSettle();

    // Deliberately no TextInputAction.done here: the point is to save while
    // the field still has focus, which is what the owner does.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title *'),
      'Rabies shot',
    );
    await tester.pumpAndSettle();
    expect(
      _focusedEditable(),
      isNotNull,
      reason: 'the title should be focused',
    );

    final dateTile = find.text('Date *');
    await tester.ensureVisible(dateTile);
    await tester.tap(dateTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final addEvent = find.widgetWithText(FilledButton, 'Add Event');
    await tester.ensureVisible(addEvent);
    await tester.tap(addEvent);
    await tester.pumpAndSettle();

    // Back on the timeline, nothing may still hold focus: an orphaned focused
    // field is what kept the keyboard on screen all the way out to the menu.
    expect(timeline.savedEvent, isNotNull);
    expect(
      _focusedEditable(),
      isNull,
      reason: 'no text field may keep focus after the form closes',
    );

    // And still nothing after walking back out to the pet list.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_focusedEditable(), isNull);
  });
}

/// The focused text field, if any.
///
/// A focused `EditableText` is what holds the platform keyboard open, so this
/// is the thing to assert on — the keyboard itself is drawn by the OS and not
/// visible to the test.
EditableText? _focusedEditable() {
  for (final element in find.byType(EditableText).evaluate()) {
    final editable = element.widget as EditableText;
    if (editable.focusNode.hasFocus) {
      return editable;
    }
  }
  return null;
}

Future<Uint8List> _makePng() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 200, 200),
    Paint()..color = const Color(0xFF1565C0),
  );
  canvas.drawCircle(
    const Offset(100, 100),
    60,
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final image = await recorder.endRecording().toImage(200, 200);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

class _FakeEventPhotoPicker implements EventPhotoPicker {
  _FakeEventPhotoPicker(this.bytes);

  final Uint8List bytes;
  EventPhotoSource? lastSource;

  @override
  Future<PickedEventPhoto?> pick(EventPhotoSource source) async {
    lastSource = source;
    return PickedEventPhoto(
      bytes: bytes,
      contentType: 'image/png',
      extension: 'png',
    );
  }

  @override
  Future<List<PickedEventPhoto>> pickMultipleFromGallery() async =>
      pick(EventPhotoSource.gallery)
          .then((p) => p == null ? <PickedEventPhoto>[] : [p]);
}

class _RecordingStorageRepository implements StorageRepository {
  int uploadCallCount = 0;
  String? uploadedPath;

  @override
  Future<void> delete(String path) async {}

  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadCallCount++;
    uploadedPath = path;
    return StorageFile(
      path: path,
      downloadUrl: Uri.parse('https://cdn.example.com/$path'),
    );
  }
}

class _MemoryPetRepository implements PetRepository {
  _MemoryPetRepository(List<Pet> seed) : _pets = List.of(seed);

  final List<Pet> _pets;
  final _controller = StreamController<List<Pet>>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  Future<Pet?> getPet({
    required EntityId userId,
    required EntityId petId,
  }) async {
    for (final pet in _pets) {
      if (pet.id == petId) {
        return pet;
      }
    }
    return null;
  }

  @override
  Future<void> savePet(Pet pet) async {
    _pets.removeWhere((existing) => existing.id == pet.id);
    _pets.add(pet);
    _controller.add(List.of(_pets));
  }

  @override
  Future<void> deletePet({
    required EntityId userId,
    required EntityId petId,
  }) async {
    _pets.removeWhere((existing) => existing.id == petId);
    _controller.add(List.of(_pets));
  }

  @override
  Stream<List<Pet>> watchPets(EntityId userId) async* {
    yield List.of(_pets);
    yield* _controller.stream;
  }
}

class _MemoryTimelineRepository implements TimelineRepository {
  final _events = <PetEvent>[];
  final _controller = StreamController<List<PetEvent>>.broadcast();

  PetEvent? get savedEvent => _events.isEmpty ? null : _events.last;

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
