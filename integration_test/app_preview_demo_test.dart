// Walks the app on a real device so its screens can be screen-recorded for
// an App Store App Preview. Guideline 2.3.4 wants captured footage of the app
// in use, which a montage of stills is not, so the recording is made from this
// run:
//
//   xcrun simctl io <udid> recordVideo --codec h264 out.mov &
//   flutter drive --driver=test_driver/screenshots.dart \
//     --target=integration_test/app_preview_demo_test.dart -d <udid>
//
// It asserts nothing. Its only job is to put each screen on the device long
// enough to read, because the screenshot suite moves through them in a few
// frames and a recording of that is a flicker.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paw_vault/app/theme/app_theme.dart';
import 'package:paw_vault/core/analytics/data/services/noop_analytics_service.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/data/services/noop_account_deletion_service.dart';
import 'package:paw_vault/core/auth/domain/repositories/account_auth_repository.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/auth/domain/services/account_deletion_service.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/core/subscription/data/services/noop_subscription_service.dart';
import 'package:paw_vault/core/subscription/domain/services/subscription_service.dart';
import 'package:paw_vault/core/subscription/presentation/cubit/subscription_cubit.dart';
import 'package:paw_vault/features/account/data/repositories/local_owner_profile_repository.dart';
import 'package:paw_vault/features/account/domain/repositories/owner_profile_repository.dart';
import 'package:paw_vault/features/documents/data/services/url_launcher_document_file_opener.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/domain/services/document_file_opener.dart';
import 'package:paw_vault/features/documents/presentation/screens/documents_screen.dart';
import 'package:paw_vault/features/pets/data/repositories/local_weight_entry_repository.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/repositories/weight_entry_repository.dart';
import 'package:paw_vault/features/pets/presentation/screens/pet_list_screen.dart';
import 'package:paw_vault/features/pets/presentation/screens/pet_profile_screen.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/reminders/domain/services/reminder_notification_scheduler.dart';
import 'package:paw_vault/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';
import 'package:paw_vault/features/smart_input/presentation/screens/smart_input_screen.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/timeline/presentation/screens/timeline_screen.dart';
import 'package:paw_vault/features/vet_summary_export/application/load_vet_summary_data.dart';
import 'package:paw_vault/features/vet_summary_export/domain/repositories/vet_summary_export_repository.dart';
import 'package:paw_vault/features/vet_summary_export/domain/services/pdf_share_service.dart';
import 'package:paw_vault/features/vet_summary_export/domain/services/vet_summary_pdf_generator.dart';
import 'package:paw_vault/features/vet_summary_export/presentation/screens/vet_summary_export_screen.dart';
import 'support/fakes.dart';
import 'support/sample_data.dart';

void main() {
  // Still required to drive the app on a device; nothing is captured through
  // it here, because the frames are taken by the screen recorder outside.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Shared fakes, seeded once.
  final auth = FakeAuthRepository();
  final pets = FakePetRepository(SampleData.pets);
  final timeline = FakeTimelineRepository(SampleData.events);
  final documents = FakeDocumentRepository(SampleData.documents);
  final reminders = FakeReminderRepository(SampleData.reminders);
  final smartInput = FakeSmartInputRepository(SampleData.smartMessages);
  final exports = FakeVetSummaryExportRepository(SampleData.exports);
  final storage = FakeStorageRepository();
  final pdfGenerator = FakeVetSummaryPdfGenerator();
  final shareService = FakePdfShareService();
  const analytics = NoopAnalyticsService();

  // Supplied to every screen. These are read by widgets that turn up on more
  // than one of them — the account action on the pet list, the subscription
  // gate and the owner's details on the profile — and a missing one throws
  // ProviderNotFoundException, which renders an error box instead of the
  // screen. That is why every App Store screenshot came out blank.
  final shared = [
    RepositoryProvider<AuthRepository>.value(value: auth),
    RepositoryProvider<AccountAuthRepository>.value(value: auth),
    RepositoryProvider<PetRepository>.value(value: pets),
    RepositoryProvider<OwnerProfileRepository>.value(
      value: LocalOwnerProfileRepository(),
    ),
    RepositoryProvider<WeightEntryRepository>.value(
      value: LocalWeightEntryRepository(),
    ),
    RepositoryProvider<SubscriptionService>.value(
      value: const NoopSubscriptionService(),
    ),
    RepositoryProvider<AccountDeletionService>.value(
      value: const NoopAccountDeletionService(),
    ),
    RepositoryProvider<StorageRepository>.value(value: storage),
    RepositoryProvider<AnalyticsService>.value(value: analytics),
    RepositoryProvider<ReminderNotificationScheduler>.value(
      value: FakeReminderNotificationScheduler(),
    ),
    // Read as the documents pane builds. The sheet it replaces on a wide
    // screen only read it once someone tapped a row, so this harness went
    // without it until the pane arrived.
    RepositoryProvider<DocumentFileOpener>.value(
      value: const UrlLauncherDocumentFileOpener(),
    ),
  ];

  const petId = 'pet-1';

  testWidgets('walk the app for an App Preview recording', (tester) async {
    /// Holds a screen on the device long enough to read.
    ///
    /// Deliberately no `convertFlutterSurfaceToImage`: that swaps the live
    /// surface for a still so screenshots can be taken, which is the one thing
    /// a recording must not have.
    /// Pumps for a wall-clock stretch, so the screen recorder has frames to
    /// capture.
    ///
    /// A plain `Future.delayed` here gave about five frames a second: in a
    /// live test nothing renders unless it is pumped, and the recording came
    /// out a slideshow. Holding a screen therefore means pumping it, not
    /// sleeping through it.
    Future<void> pumpFor(Duration total) async {
      final end = DateTime.now().add(total);
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    /// Seven screens have to fit inside Apple's 30-second cap, which works
    /// out at a little over four seconds each once mounting and settling are
    /// counted. Lengthen these and the walk no longer fits.
    Future<void> hold(Widget app) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      await pumpFor(const Duration(milliseconds: 850));

      // A short nudge down, so the frame has some movement in it. On a screen
      // with little to scroll it springs back, which is fine.
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -160));
        await tester.pumpAndSettle();
        await pumpFor(const Duration(milliseconds: 550));
      }

      await pumpFor(const Duration(milliseconds: 600));
    }

    MaterialApp wrap(Widget home) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: BlocProvider<SubscriptionCubit>(
            create: (_) => SubscriptionCubit(const NoopSubscriptionService()),
            child: home,
          ),
        );

    await hold(
      MultiRepositoryProvider(
        providers: [
          ...shared,
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<AccountAuthRepository>.value(value: auth),
          RepositoryProvider<PetRepository>.value(value: pets),
        ],
        child: wrap(const PetListScreen()),
      ),
    );

    await hold(
      MultiRepositoryProvider(
        providers: [
          ...shared,
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<PetRepository>.value(value: pets),
        ],
        child: wrap(const PetProfileScreen(petId: petId)),
      ),
    );

    await hold(
      MultiRepositoryProvider(
        providers: [
          ...shared,
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<TimelineRepository>.value(value: timeline),
        ],
        child: wrap(const TimelineScreen(petId: petId)),
      ),
    );

    await hold(
      MultiRepositoryProvider(
        providers: [
          ...shared,
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<DocumentRepository>.value(value: documents),
        ],
        child: wrap(const DocumentsScreen(petId: petId)),
      ),
    );

    await hold(
      MultiRepositoryProvider(
        providers: [
          ...shared,
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<ReminderRepository>.value(value: reminders),
        ],
        child: wrap(const RemindersScreen(petId: petId)),
      ),
    );

    await hold(
      MultiRepositoryProvider(
        providers: [
          ...shared,
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<AnalyticsService>.value(value: analytics),
          RepositoryProvider<SmartInputRepository>.value(value: smartInput),
        ],
        child: wrap(const SmartInputScreen(petId: petId)),
      ),
    );

    await hold(
      MultiRepositoryProvider(
        providers: [
          ...shared,
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<AnalyticsService>.value(value: analytics),
          RepositoryProvider<StorageRepository>.value(value: storage),
          RepositoryProvider<VetSummaryExportRepository>.value(value: exports),
          RepositoryProvider<VetSummaryPdfGenerator>.value(value: pdfGenerator),
          RepositoryProvider<PdfShareService>.value(value: shareService),
          RepositoryProvider<LoadVetSummaryData>.value(
            value: LoadVetSummaryData(
              petRepository: pets,
              timelineRepository: timeline,
              documentRepository: documents,
              reminderRepository: reminders,
              pawCheckRepository: FakePawCheckRepository(),
            ),
          ),
        ],
        child: wrap(const VetSummaryExportScreen(petId: petId)),
      ),
    );
  });
}
