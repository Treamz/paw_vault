import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/app/router/app_router.dart';
import 'package:paw_vault/app/theme/app_theme.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/analytics/presentation/analytics_route_observer.dart';
import 'package:paw_vault/core/auth/domain/repositories/account_auth_repository.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/auth/domain/services/account_deletion_service.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/core/subscription/domain/services/paywall_presenter.dart';
import 'package:paw_vault/core/subscription/domain/services/subscription_service.dart';
import 'package:paw_vault/core/subscription/presentation/cubit/subscription_cubit.dart';
import 'package:paw_vault/features/document_extraction/domain/repositories/document_extraction_ai_repository.dart';
import 'package:paw_vault/features/document_extraction/domain/services/document_source_picker.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/domain/services/document_file_opener.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/services/pet_photo_picker.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/reminders/domain/services/reminder_notification_scheduler.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/ai_repository.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/timeline/domain/services/event_photo_picker.dart';
import 'package:paw_vault/features/vet_summary_export/application/load_vet_summary_data.dart';
import 'package:paw_vault/features/vet_summary_export/domain/repositories/vet_summary_export_repository.dart';
import 'package:paw_vault/features/vet_summary_export/domain/services/pdf_share_service.dart';
import 'package:paw_vault/features/vet_summary_export/domain/services/vet_summary_pdf_generator.dart';

class PawVaultApp extends StatefulWidget {
  const PawVaultApp({
    required this.dependencies,
    super.key,
  });

  final AppDependencies dependencies;

  @override
  State<PawVaultApp> createState() => _PawVaultAppState();
}

class _PawVaultAppState extends State<PawVaultApp> {
  late final AppRouter _appRouter;
  late final AnalyticsRouteObserver _analyticsObserver;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter();
    _analyticsObserver =
        AnalyticsRouteObserver(widget.dependencies.analyticsService);

    // Ask for App Tracking Transparency permission once the first frame is up,
    // so iOS shows the system prompt while the app is active. Required before
    // collecting any data Apple treats as tracking (Guideline 5.1.2(i)).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.dependencies.trackingAuthorizationService.requestAuthorization();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(
          value: widget.dependencies.authRepository,
        ),
        RepositoryProvider<AccountAuthRepository>.value(
          value: widget.dependencies.accountAuthRepository,
        ),
        RepositoryProvider<AccountDeletionService>.value(
          value: widget.dependencies.accountDeletionService,
        ),
        RepositoryProvider<StorageRepository>.value(
          value: widget.dependencies.storageRepository,
        ),
        RepositoryProvider<PetRepository>.value(
          value: widget.dependencies.petRepository,
        ),
        RepositoryProvider<PetPhotoPicker>.value(
          value: widget.dependencies.petPhotoPicker,
        ),
        RepositoryProvider<TimelineRepository>.value(
          value: widget.dependencies.timelineRepository,
        ),
        RepositoryProvider<EventPhotoPicker>.value(
          value: widget.dependencies.eventPhotoPicker,
        ),
        RepositoryProvider<DocumentRepository>.value(
          value: widget.dependencies.documentRepository,
        ),
        RepositoryProvider<FilePicker>.value(
          value: widget.dependencies.filePicker,
        ),
        RepositoryProvider<DocumentFileOpener>.value(
          value: widget.dependencies.documentFileOpener,
        ),
        RepositoryProvider<DocumentExtractionAiRepository>.value(
          value: widget.dependencies.documentExtractionAiRepository,
        ),
        RepositoryProvider<DocumentSourcePicker>.value(
          value: widget.dependencies.documentSourcePicker,
        ),
        RepositoryProvider<ReminderNotificationScheduler>.value(
          value: widget.dependencies.reminderNotificationScheduler,
        ),
        RepositoryProvider<ReminderRepository>.value(
          value: widget.dependencies.reminderRepository,
        ),
        RepositoryProvider<AiRepository>.value(
          value: widget.dependencies.aiRepository,
        ),
        RepositoryProvider<SmartInputRepository>.value(
          value: widget.dependencies.smartInputRepository,
        ),
        RepositoryProvider<VetSummaryExportRepository>.value(
          value: widget.dependencies.vetSummaryExportRepository,
        ),
        RepositoryProvider<LoadVetSummaryData>.value(
          value: widget.dependencies.loadVetSummaryData,
        ),
        RepositoryProvider<VetSummaryPdfGenerator>.value(
          value: widget.dependencies.vetSummaryPdfGenerator,
        ),
        RepositoryProvider<PdfShareService>.value(
          value: widget.dependencies.pdfShareService,
        ),
        RepositoryProvider<AnalyticsService>.value(
          value: widget.dependencies.analyticsService,
        ),
        RepositoryProvider<SubscriptionService>.value(
          value: widget.dependencies.subscriptionService,
        ),
        RepositoryProvider<PaywallPresenter>.value(
          value: widget.dependencies.paywallPresenter,
        ),
      ],
      child: BlocProvider<SubscriptionCubit>(
        create: (_) =>
            SubscriptionCubit(widget.dependencies.subscriptionService),
        child: MaterialApp.router(
          title: 'PawVault',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          routerConfig: _appRouter.config(
            navigatorObservers: () => [_analyticsObserver],
          ),
          // Dismiss the keyboard when tapping anywhere outside a text field;
          // otherwise it stays open after entering text.
          builder: (context, child) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child,
          ),
        ),
      ),
    );
  }
}
