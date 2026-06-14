// Renders each primary screen with seeded sample data and captures a
// screenshot for the App Store. Run via tool/screenshots.sh (or `flutter drive`
// with test_driver/screenshots.dart) on the required simulator sizes.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:paw_vault/app/theme/app_theme.dart';
import 'package:paw_vault/core/analytics/data/services/noop_analytics_service.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/repositories/account_auth_repository.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/presentation/screens/documents_screen.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/presentation/screens/pet_list_screen.dart';
import 'package:paw_vault/features/pets/presentation/screens/pet_profile_screen.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
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
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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

  const petId = 'pet-1';

  testWidgets('capture App Store screenshots', (tester) async {
    var surfaceConverted = false;

    Future<void> shoot(String name, Widget app) async {
      await tester.pumpWidget(app);
      if (!surfaceConverted) {
        await binding.convertFlutterSurfaceToImage();
        surfaceConverted = true;
      }
      // Let streams settle and the first frame fully render.
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 200));
      await binding.takeScreenshot(name);
    }

    MaterialApp wrap(Widget home) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: home,
        );

    await shoot(
      '01_pets',
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<AccountAuthRepository>.value(value: auth),
          RepositoryProvider<PetRepository>.value(value: pets),
        ],
        child: wrap(const PetListScreen()),
      ),
    );

    await shoot(
      '02_profile',
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<PetRepository>.value(value: pets),
        ],
        child: wrap(const PetProfileScreen(petId: petId)),
      ),
    );

    await shoot(
      '03_timeline',
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<TimelineRepository>.value(value: timeline),
        ],
        child: wrap(const TimelineScreen(petId: petId)),
      ),
    );

    await shoot(
      '04_documents',
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<DocumentRepository>.value(value: documents),
        ],
        child: wrap(const DocumentsScreen(petId: petId)),
      ),
    );

    await shoot(
      '05_reminders',
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<ReminderRepository>.value(value: reminders),
        ],
        child: wrap(const RemindersScreen(petId: petId)),
      ),
    );

    await shoot(
      '06_smart_input',
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<AnalyticsService>.value(value: analytics),
          RepositoryProvider<SmartInputRepository>.value(value: smartInput),
        ],
        child: wrap(const SmartInputScreen(petId: petId)),
      ),
    );

    await shoot(
      '07_vet_summary',
      MultiRepositoryProvider(
        providers: [
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
            ),
          ),
        ],
        child: wrap(const VetSummaryExportScreen(petId: petId)),
      ),
    );
  });
}
