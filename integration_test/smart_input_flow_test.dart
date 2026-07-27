// Drives the real app through the Smart Input flow: sentence-capitalized
// input, Analyze producing a draft shown at the top with a confirmation
// notice, and confirming the draft into saved entries. The AI boundary is
// faked. Run with the screenshot driver:
//
//   SCREENSHOT_DIR=build/verify_screenshots flutter drive \
//     --driver=test_driver/screenshots.dart \
//     --target=integration_test/smart_input_flow_test.dart \
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
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smart input shows the draft on top and saves on confirm',
      (tester) async {
    final smartInput = _FakeSmartInputRepository();
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
      smartInputRepository: smartInput,
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

    // Navigate: pet list -> profile -> Smart Input.
    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    final smartInputTile = find.text('Smart Input');
    await tester.ensureVisible(smartInputTile);
    await tester.tap(smartInputTile);
    await tester.pumpAndSettle();

    // The input capitalizes sentences.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.textCapitalization, TextCapitalization.sentences);

    // Analyze produces a draft shown at the top with the notice.
    await tester.enterText(
      find.byType(TextField),
      'Bella got her rabies shot today. Next one in a year.',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analyze'));
    await tester.pumpAndSettle();

    expect(find.text('AI draft'), findsOneWidget);
    expect(
      find.text('Nothing is saved until you confirm. Review the draft below.'),
      findsOneWidget,
    );
    final draftY = tester.getTopLeft(find.text('AI draft')).dy;
    final inputY = tester.getTopLeft(find.byType(TextField)).dy;
    expect(draftY, lessThan(inputY));
    await binding.takeScreenshot('01_smart_input_draft_on_top');

    // Nothing is saved yet.
    expect(smartInput.savedMessages, isEmpty);

    // Confirm persists the entry into history.
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(smartInput.savedMessages, hasLength(1));
    expect(find.text('Saved to records'), findsOneWidget);
    await binding.takeScreenshot('02_smart_input_saved_entry');
  });
}

class _FakeSmartInputRepository implements SmartInputRepository {
  final savedMessages = <SmartMessage>[];
  final _controller = StreamController<List<SmartMessage>>.broadcast();

  @override
  Future<SmartInputDraft> createDraft(String input) async {
    return SmartInputDraft(
      originalText: input,
      requiresConfirmation: true,
      detectedIntent: SmartMessageIntent.addVaccination,
      extractedData: const {'vaccine': 'rabies', 'next due': 'in a year'},
      suggestedActions: const [
        SmartSuggestedAction(
          type: SmartSuggestedActionType.createTimelineEvent,
        ),
        SmartSuggestedAction(type: SmartSuggestedActionType.createReminder),
      ],
      confidence: 0.92,
    );
  }

  @override
  Stream<List<SmartMessage>> watchSmartMessages({
    required EntityId userId,
    required EntityId petId,
  }) async* {
    yield List.of(savedMessages);
    yield* _controller.stream;
  }

  @override
  Future<SmartMessage?> getSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) async =>
      null;

  @override
  Future<void> saveSmartMessage(SmartMessage message) async {
    savedMessages.add(message);
    _controller.add(List.of(savedMessages));
  }

  @override
  Future<void> deleteSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) async {}
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
