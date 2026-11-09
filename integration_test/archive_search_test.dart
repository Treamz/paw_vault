// Drives the archive's two searchable lists on a real device and captures
// what the search looks like, including the state where it finds nothing.
//
//   SCREENSHOT_DIR=build/verify_screenshots \
//   flutter drive --driver=test_driver/screenshots.dart \
//     --target=integration_test/archive_search_test.dart -d <udid>
//
// Worth running on a phone and on an unfolded iPhone Duo: on the Duo the
// search box sits in the 420pt list pane beside the detail pane, which is the
// narrowest place it has to fit.
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
import 'package:paw_vault/features/reminders/domain/services/reminder_notification_scheduler.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/timeline/presentation/screens/timeline_screen.dart';
import 'support/fakes.dart';
import 'support/sample_data.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final auth = FakeAuthRepository();
  final pets = FakePetRepository(SampleData.pets);
  final timeline = FakeTimelineRepository(SampleData.events);
  final documents = FakeDocumentRepository(SampleData.documents);
  final storage = FakeStorageRepository();
  const analytics = NoopAnalyticsService();

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
    RepositoryProvider<DocumentFileOpener>.value(
      value: const UrlLauncherDocumentFileOpener(),
    ),
  ];

  const petId = 'pet-1';

  testWidgets('search the archive', (tester) async {
    var surfaceConverted = false;

    Future<void> settle() async {
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 200));
    }

    Future<void> shoot(String name) async {
      if (!surfaceConverted) {
        await binding.convertFlutterSurfaceToImage();
        surfaceConverted = true;
      }
      await settle();
      await binding.takeScreenshot(name);
    }

    MaterialApp wrap(Widget home) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: BlocProvider<SubscriptionCubit>(
            create: (_) => SubscriptionCubit(const NoopSubscriptionService()),
            child: home,
          ),
        );

    Future<void> search(String query) async {
      await tester.enterText(find.byType(TextField).first, query);
      await settle();
    }

    // ---- Documents -------------------------------------------------------
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          ...shared,
          RepositoryProvider<DocumentRepository>.value(value: documents),
        ],
        child: wrap(const DocumentsScreen(petId: petId)),
      ),
    );
    await shoot('01_documents_before_search');

    await search('rabies');
    await shoot('02_documents_search');

    await search('zzz');
    await shoot('03_documents_no_match');

    // ---- Timeline --------------------------------------------------------
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          ...shared,
          RepositoryProvider<TimelineRepository>.value(value: timeline),
        ],
        child: wrap(const TimelineScreen(petId: petId)),
      ),
    );
    await shoot('04_timeline_before_search');

    await search('rabies');
    await shoot('05_timeline_search');

    await search('zzz');
    await shoot('06_timeline_no_match');
  });
}
