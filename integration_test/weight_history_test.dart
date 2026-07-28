// Drives the real app through the weight history feature: chart + entries
// list, adding a measurement via the dialog, and the pet's current weight
// following the newest entry. Run with the screenshot driver:
//
//   SCREENSHOT_DIR=build/verify_screenshots flutter drive \
//     --driver=test_driver/screenshots.dart \
//     --target=integration_test/weight_history_test.dart \
//     -d <simulator-udid>
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/data/repositories/local_weight_entry_repository.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/entities/weight_entry.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('weight history shows a chart and adding entries updates it',
      (tester) async {
    final weightEntries = LocalWeightEntryRepository();
    const petId = EntityId('pet-1');
    const userId = EntityId('local-anonymous-user');
    await weightEntries.saveEntry(
      const WeightEntry(
        id: EntityId('w1'),
        userId: userId,
        petId: petId,
        value: 4.8,
        date: DateOnly(year: 2026, month: 3, day: 2),
      ),
    );
    await weightEntries.saveEntry(
      const WeightEntry(
        id: EntityId('w2'),
        userId: userId,
        petId: petId,
        value: 5.4,
        date: DateOnly(year: 2026, month: 5, day: 10),
      ),
    );
    await weightEntries.saveEntry(
      const WeightEntry(
        id: EntityId('w3'),
        userId: userId,
        petId: petId,
        value: 5.9,
        date: DateOnly(year: 2026, month: 7, day: 20),
      ),
    );

    final pets = _MemoryPetRepository(const [
      Pet(
        id: petId,
        userId: userId,
        name: 'Rex',
        species: 'Dog',
        weight: PetWeight(value: 5.9),
      ),
    ]);
    final base = AppDependencies.localFirst();
    final dependencies = AppDependencies(
      weightEntryRepository: weightEntries,
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

    // Navigate: pet list -> profile -> Weight.
    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    final weightTile = find.widgetWithText(ListTile, 'Weight');
    await tester.ensureVisible(weightTile);
    await tester.tap(weightTile);
    await tester.pumpAndSettle();

    // Chart plus the three seeded entries.
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('5.9 kg'), findsOneWidget);
    expect(find.text('5.4 kg'), findsOneWidget);
    expect(find.text('4.8 kg'), findsOneWidget);
    await binding.takeScreenshot('01_weight_history_chart');

    // Add a new measurement via the dialog.
    await tester.tap(find.text('Add weight'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Weight'), '7.2');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('7.2 kg'), findsOneWidget);
    // The newest entry becomes the pet's current weight.
    expect(pets.savedPet?.weight?.value, 7.2);
    await binding.takeScreenshot('02_weight_history_added');
  });
}

class _MemoryPetRepository implements PetRepository {
  _MemoryPetRepository(List<Pet> seed) : _pets = List.of(seed);

  final List<Pet> _pets;
  Pet? savedPet;

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
    savedPet = pet;
    _pets.removeWhere((existing) => existing.id == pet.id);
    _pets.add(pet);
  }

  @override
  Future<void> deletePet({
    required EntityId userId,
    required EntityId petId,
  }) async {
    _pets.removeWhere((existing) => existing.id == petId);
  }

  @override
  Stream<List<Pet>> watchPets(EntityId userId) =>
      Stream<List<Pet>>.value(List.of(_pets));
}
