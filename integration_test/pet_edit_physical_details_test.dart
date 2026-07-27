// Drives the real app through editing a pet's Physical Details (weight)
// from the profile screen, capturing verification screenshots along the way.
// Run with the screenshot driver so the images are written to disk:
//
//   SCREENSHOT_DIR=build/verify_screenshots flutter drive \
//     --driver=test_driver/screenshots.dart \
//     --target=integration_test/pet_edit_physical_details_test.dart \
//     -d <simulator-udid>
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('editing Physical Details from the pet profile', (tester) async {
    final pets = _MemoryPetRepository([
      const Pet(
        id: EntityId('pet-1'),
        userId: EntityId('local-anonymous-user'),
        name: 'Rex',
        species: 'Dog',
        weight: PetWeight(value: 5),
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

    // Open the pet profile: Physical Details shows the seeded weight.
    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    expect(find.text('Physical Details'), findsOneWidget);
    expect(find.text('5.0 kilogram'), findsOneWidget);
    await binding.takeScreenshot('01_profile_physical_details');

    // Open the edit form via the new edit action; weight is prefilled.
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Edit Pet'), findsOneWidget);
    final weightField = find.widgetWithText(TextFormField, 'Weight');
    expect(
      tester.widget<TextFormField>(weightField).controller?.text,
      '5.0',
    );
    await binding.takeScreenshot('02_edit_form_prefilled');

    // Change the weight, dismiss the keyboard, and save.
    await tester.ensureVisible(weightField);
    await tester.enterText(weightField, '6.5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final saveButton = find.widgetWithText(ElevatedButton, 'Save Changes');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Saved and back on the reloaded profile with the new weight.
    expect(pets.lastSaved?.weight?.value, 6.5);
    expect(find.text('Pet Profile'), findsOneWidget);
    expect(find.text('6.5 kilogram'), findsOneWidget);
    await binding.takeScreenshot('03_profile_updated');
  });
}

class _MemoryPetRepository implements PetRepository {
  _MemoryPetRepository(List<Pet> seed) : _pets = List.of(seed);

  final List<Pet> _pets;
  final _controller = StreamController<List<Pet>>.broadcast();

  Pet? get lastSaved => _pets.isEmpty ? null : _pets.last;

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
