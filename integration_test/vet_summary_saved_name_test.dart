// Verifies that a vet summary saved inside the app keeps the name the owner
// entered, instead of being listed by the time it was saved.
//
// Run it with the screenshot driver:
//
//   flutter drive --driver=test_driver/screenshots.dart \
//     --target=integration_test/vet_summary_saved_name_test.dart \
//     -d <simulator-udid>
//
// `binding.takeScreenshot` works on iOS here. If the PNGs come out blank and
// byte-identical, check for an undismissed system permission alert covering
// the app, and for widgets failing to build in the harness -- both render an
// empty surface. See the screenshot task in .ai/TASKS.md.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_export.dart';
import 'package:paw_vault/features/vet_summary_export/domain/repositories/vet_summary_export_repository.dart';

import 'support/fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a saved summary keeps the name the owner entered',
      (tester) async {
    final exports = _MemoryVetSummaryExportRepository();
    final base = AppDependencies.localFirst();
    final dependencies = AppDependencies(
      authRepository: base.authRepository,
      storageRepository: base.storageRepository,
      petRepository: FakePetRepository(const [
        Pet(
          id: EntityId('pet-1'),
          userId: EntityId('local-anonymous-user'),
          name: 'Jotaro',
        ),
      ]),
      timelineRepository: base.timelineRepository,
      documentRepository: base.documentRepository,
      reminderRepository: base.reminderRepository,
      aiRepository: base.aiRepository,
      smartInputRepository: base.smartInputRepository,
      vetSummaryExportRepository: exports,
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
    await tester.pumpAndSettle();

    // Navigate: pet list -> profile -> Vet Summary.
    await tester.tap(find.text('Jotaro'));
    await tester.pumpAndSettle();
    final entry = find.text('Vet Summary');
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Generate summary'));
    await tester.pumpAndSettle();

    // The app suggests a name derived from the pet.
    expect(
      find.widgetWithText(TextField, 'Jotaro_vet_summary.pdf'),
      findsOneWidget,
    );

    final save = find.text('Save copy');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    // The reported bug: the record was saved with no name, so the list
    // showed the time it was saved instead.
    expect(exports.saved.single.fileName, 'Jotaro_vet_summary.pdf');
    expect(find.text('Jotaro_vet_summary.pdf'), findsWidgets);
  });

  testWidgets('a renamed summary is saved and listed under the new name',
      (tester) async {
    final exports = _MemoryVetSummaryExportRepository();
    final base = AppDependencies.localFirst();
    final dependencies = AppDependencies(
      authRepository: base.authRepository,
      storageRepository: base.storageRepository,
      petRepository: FakePetRepository(const [
        Pet(
          id: EntityId('pet-1'),
          userId: EntityId('local-anonymous-user'),
          name: 'Jotaro',
        ),
      ]),
      timelineRepository: base.timelineRepository,
      documentRepository: base.documentRepository,
      reminderRepository: base.reminderRepository,
      aiRepository: base.aiRepository,
      smartInputRepository: base.smartInputRepository,
      vetSummaryExportRepository: exports,
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
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jotaro'));
    await tester.pumpAndSettle();
    final entry = find.text('Vet Summary');
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate summary'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Jotaro annual checkup');
    await tester.pumpAndSettle();

    final save = find.text('Save copy');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(exports.saved.single.fileName, 'Jotaro annual checkup.pdf');
    expect(find.text('Jotaro annual checkup.pdf'), findsWidgets);
  });

  testWidgets('a summary whose save is not yet confirmed still lists',
      (tester) async {
    // A summary is written with a Firestore server timestamp, which reads
    // back null until the server acknowledges it. That used to fail the
    // snapshot and replace the whole history with a mapping error.
    final exports = _MemoryVetSummaryExportRepository()
      ..saved.add(
        const VetSummaryExport(
          id: EntityId('export-1'),
          userId: EntityId('local-anonymous-user'),
          petId: EntityId('pet-1'),
          fileName: 'Jotaro_vet_summary.pdf',
        ),
      );
    final base = AppDependencies.localFirst();
    final dependencies = AppDependencies(
      authRepository: base.authRepository,
      storageRepository: base.storageRepository,
      petRepository: FakePetRepository(const [
        Pet(
          id: EntityId('pet-1'),
          userId: EntityId('local-anonymous-user'),
          name: 'Jotaro',
        ),
      ]),
      timelineRepository: base.timelineRepository,
      documentRepository: base.documentRepository,
      reminderRepository: base.reminderRepository,
      aiRepository: base.aiRepository,
      smartInputRepository: base.smartInputRepository,
      vetSummaryExportRepository: exports,
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
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jotaro'));
    await tester.pumpAndSettle();
    final entry = find.text('Vet Summary');
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.text('Jotaro_vet_summary.pdf'), findsOneWidget);
    expect(find.text('Saving…'), findsOneWidget);
    expect(find.textContaining('FirestoreMappingException'), findsNothing);
  });
}

class _MemoryVetSummaryExportRepository implements VetSummaryExportRepository {
  final saved = <VetSummaryExport>[];
  final _controller = StreamController<List<VetSummaryExport>>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveExport(VetSummaryExport summaryExport) async {
    saved.removeWhere((existing) => existing.id == summaryExport.id);
    saved.add(summaryExport);
    _controller.add(List.of(saved));
  }

  @override
  Future<VetSummaryExport?> getExport({
    required EntityId userId,
    required EntityId petId,
    required EntityId exportId,
  }) async {
    for (final summaryExport in saved) {
      if (summaryExport.id == exportId) {
        return summaryExport;
      }
    }
    return null;
  }

  @override
  Future<void> deleteExport({
    required EntityId userId,
    required EntityId petId,
    required EntityId exportId,
  }) async {
    saved.removeWhere((existing) => existing.id == exportId);
    _controller.add(List.of(saved));
  }

  @override
  Stream<List<VetSummaryExport>> watchExports({
    required EntityId userId,
    required EntityId petId,
  }) async* {
    yield List.of(saved);
    yield* _controller.stream;
  }
}
