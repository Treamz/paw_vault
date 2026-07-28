// Verifies QA batch 5's visible changes in the Add Event form: fields are
// not painted red before a save attempt, errors appear only after tapping
// Add Event, and attachments offer a device-file option. Run with the
// screenshot driver:
//
//   SCREENSHOT_DIR=build/verify_screenshots flutter drive \
//     --driver=test_driver/screenshots.dart \
//     --target=integration_test/qa_batch5_test.dart \
//     -d <simulator-udid>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('event form defers validation and offers file attachments',
      (tester) async {
    final pets = _FakePetRepository(const [
      Pet(
        id: EntityId('pet-1'),
        userId: EntityId('local-anonymous-user'),
        name: 'Rex',
      ),
    ]);
    final base = AppDependencies.localFirst();
    final dependencies = AppDependencies(
      authRepository: base.authRepository,
      storageRepository: base.storageRepository,
      petRepository: pets,
      timelineRepository: base.timelineRepository,
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

    // Navigate: pet list -> profile -> Timeline -> Add Event.
    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    final timelineTile = find.text('Timeline');
    await tester.ensureVisible(timelineTile);
    await tester.tap(timelineTile);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add event'));
    await tester.pumpAndSettle();

    // Selecting a type must NOT paint the untouched fields red.
    await tester.tap(find.byType(DropdownButtonFormField<PetEventType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vaccination').last);
    await tester.pumpAndSettle();
    expect(find.text('Event title is required'), findsNothing);
    expect(find.text('Event date is required'), findsNothing);
    // Attachments now include a device-file option.
    final fileButton = find.widgetWithText(OutlinedButton, 'File');
    await tester.ensureVisible(fileButton);
    expect(fileButton, findsOneWidget);
    await binding.takeScreenshot('01_event_form_no_premature_errors');

    // Errors appear only after attempting to save.
    final addEvent = find.widgetWithText(ElevatedButton, 'Add Event');
    await tester.ensureVisible(addEvent);
    await tester.tap(addEvent);
    await tester.pumpAndSettle();
    expect(find.text('Event title is required'), findsOneWidget);
    expect(find.text('Event date is required'), findsOneWidget);
    await binding.takeScreenshot('02_event_form_errors_after_save');
  });
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
