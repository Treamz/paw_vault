import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:paw_vault/core/ai/data/datasources/flutter_fire_ai_logic_data_source.dart';
import 'package:paw_vault/core/ai/data/datasources/noop_firebase_ai_logic_data_source.dart';
import 'package:paw_vault/core/analytics/data/services/firebase_analytics_service.dart';
import 'package:paw_vault/core/analytics/data/services/noop_analytics_service.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/data/datasources/flutter_fire_auth_data_source.dart';
import 'package:paw_vault/core/auth/data/datasources/noop_firebase_auth_data_source.dart';
import 'package:paw_vault/core/auth/data/repositories/firebase_ready_auth_repository.dart';
import 'package:paw_vault/core/auth/data/services/firebase_account_deletion_service.dart';
import 'package:paw_vault/core/auth/data/services/noop_account_deletion_service.dart';
import 'package:paw_vault/core/auth/domain/repositories/account_auth_repository.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/auth/domain/services/account_deletion_service.dart';
import 'package:paw_vault/core/firebase/firebase_instances.dart';
import 'package:paw_vault/core/storage/data/datasources/flutter_fire_storage_data_source.dart';
import 'package:paw_vault/core/storage/data/datasources/noop_firebase_storage_data_source.dart';
import 'package:paw_vault/core/storage/data/repositories/firebase_ready_storage_repository.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/core/subscription/data/services/noop_paywall_presenter.dart';
import 'package:paw_vault/core/subscription/data/services/noop_subscription_service.dart';
import 'package:paw_vault/core/subscription/domain/services/paywall_presenter.dart';
import 'package:paw_vault/core/subscription/domain/services/subscription_service.dart';
import 'package:paw_vault/core/tracking/data/services/att_tracking_authorization_service.dart';
import 'package:paw_vault/core/tracking/data/services/noop_tracking_authorization_service.dart';
import 'package:paw_vault/core/tracking/domain/services/tracking_authorization_service.dart';
import 'package:paw_vault/features/account/data/repositories/firebase_owner_profile_repository.dart';
import 'package:paw_vault/features/account/data/repositories/local_owner_profile_repository.dart';
import 'package:paw_vault/features/account/domain/repositories/owner_profile_repository.dart';
import 'package:paw_vault/features/document_extraction/data/repositories/firebase_ready_document_extraction_ai_repository.dart';
import 'package:paw_vault/features/document_extraction/data/services/document_source_picker_impl.dart';
import 'package:paw_vault/features/document_extraction/domain/repositories/document_extraction_ai_repository.dart';
import 'package:paw_vault/features/document_extraction/domain/services/document_source_picker.dart';
import 'package:paw_vault/features/documents/data/datasources/flutter_fire_document_data_source.dart';
import 'package:paw_vault/features/documents/data/repositories/firebase_document_repository.dart';
import 'package:paw_vault/features/documents/data/repositories/local_document_repository.dart';
import 'package:paw_vault/features/documents/data/services/file_picker_impl.dart';
import 'package:paw_vault/features/documents/data/services/url_launcher_document_file_opener.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/domain/services/document_file_opener.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/pets/data/datasources/flutter_fire_pet_data_source.dart';
import 'package:paw_vault/features/pets/data/repositories/firebase_pet_repository.dart';
import 'package:paw_vault/features/pets/data/repositories/firebase_weight_entry_repository.dart';
import 'package:paw_vault/features/pets/data/repositories/local_pet_repository.dart';
import 'package:paw_vault/features/pets/data/repositories/local_weight_entry_repository.dart';
import 'package:paw_vault/features/pets/data/services/pet_photo_picker_impl.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/repositories/weight_entry_repository.dart';
import 'package:paw_vault/features/pets/domain/services/pet_photo_picker.dart';
import 'package:paw_vault/features/reminders/data/datasources/flutter_fire_reminder_data_source.dart';
import 'package:paw_vault/features/reminders/data/repositories/firebase_reminder_repository.dart';
import 'package:paw_vault/features/reminders/data/repositories/local_reminder_repository.dart';
import 'package:paw_vault/features/reminders/data/services/local_reminder_notification_scheduler.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/reminders/domain/services/reminder_notification_scheduler.dart';
import 'package:paw_vault/features/smart_input/data/datasources/flutter_fire_smart_input_data_source.dart';
import 'package:paw_vault/features/smart_input/data/repositories/firebase_ready_ai_repository.dart';
import 'package:paw_vault/features/smart_input/data/repositories/firebase_smart_input_repository.dart';
import 'package:paw_vault/features/smart_input/data/repositories/noop_smart_input_repository.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/ai_repository.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';
import 'package:paw_vault/features/timeline/data/datasources/flutter_fire_timeline_data_source.dart';
import 'package:paw_vault/features/timeline/data/repositories/firebase_timeline_repository.dart';
import 'package:paw_vault/features/timeline/data/repositories/local_timeline_repository.dart';
import 'package:paw_vault/features/timeline/data/services/event_photo_picker_impl.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/timeline/domain/services/event_photo_picker.dart';
import 'package:paw_vault/features/vet_summary_export/application/load_vet_summary_data.dart';
import 'package:paw_vault/features/vet_summary_export/data/datasources/flutter_fire_vet_summary_export_data_source.dart';
import 'package:paw_vault/features/vet_summary_export/data/repositories/firebase_vet_summary_export_repository.dart';
import 'package:paw_vault/features/vet_summary_export/data/repositories/local_vet_summary_export_repository.dart';
import 'package:paw_vault/features/vet_summary_export/data/services/printing_pdf_share_service.dart';
import 'package:paw_vault/features/vet_summary_export/data/services/vet_summary_pdf_builder.dart';
import 'package:paw_vault/features/vet_summary_export/domain/repositories/vet_summary_export_repository.dart';
import 'package:paw_vault/features/vet_summary_export/domain/services/pdf_share_service.dart';
import 'package:paw_vault/features/vet_summary_export/domain/services/vet_summary_pdf_generator.dart';

class AppDependencies {
  AppDependencies({
    OwnerProfileRepository? ownerProfileRepository,
    WeightEntryRepository? weightEntryRepository,
    required this.authRepository,
    required this.storageRepository,
    required this.petRepository,
    required this.timelineRepository,
    required this.documentRepository,
    required this.reminderRepository,
    required this.aiRepository,
    required this.smartInputRepository,
    required this.vetSummaryExportRepository,
    required this.filePicker,
    required this.documentFileOpener,
    required this.documentExtractionAiRepository,
    required this.documentSourcePicker,
    required this.petPhotoPicker,
    required this.eventPhotoPicker,
    required this.reminderNotificationScheduler,
    required this.analyticsService,
    required this.subscriptionService,
    required this.paywallPresenter,
    required this.trackingAuthorizationService,
    required this.accountDeletionService,
  })  : ownerProfileRepository =
            ownerProfileRepository ?? LocalOwnerProfileRepository(),
        weightEntryRepository =
            weightEntryRepository ?? LocalWeightEntryRepository();

  factory AppDependencies.localFirst() {
    final authDataSource = NoopFirebaseAuthDataSource();
    final storageDataSource = NoopFirebaseStorageDataSource();
    final aiDataSource = NoopFirebaseAiLogicDataSource();
    final aiRepository = FirebaseReadyAiRepository(aiDataSource);

    return AppDependencies(
      authRepository: FirebaseReadyAuthRepository(authDataSource),
      storageRepository: FirebaseReadyStorageRepository(storageDataSource),
      petRepository: LocalPetRepository(),
      timelineRepository: LocalTimelineRepository(),
      documentRepository: LocalDocumentRepository(),
      reminderRepository: LocalReminderRepository(),
      aiRepository: aiRepository,
      smartInputRepository: NoopSmartInputRepository(aiRepository),
      vetSummaryExportRepository: LocalVetSummaryExportRepository(),
      filePicker: const FilePickerImpl(),
      documentFileOpener: const UrlLauncherDocumentFileOpener(),
      documentExtractionAiRepository:
          FirebaseReadyDocumentExtractionAiRepository(aiDataSource),
      documentSourcePicker: DocumentSourcePickerImpl(),
      petPhotoPicker: PetPhotoPickerImpl(),
      eventPhotoPicker: EventPhotoPickerImpl(),
      reminderNotificationScheduler:
          LocalReminderNotificationScheduler(FlutterLocalNotificationsPlugin()),
      analyticsService: const NoopAnalyticsService(),
      subscriptionService: const NoopSubscriptionService(),
      paywallPresenter: const NoopPaywallPresenter(),
      trackingAuthorizationService: const NoopTrackingAuthorizationService(),
      accountDeletionService: const NoopAccountDeletionService(),
    );
  }

  factory AppDependencies.firebaseReady(
    FirebaseInstances firebase, {
    SubscriptionService subscriptionService = const NoopSubscriptionService(),
    PaywallPresenter paywallPresenter = const NoopPaywallPresenter(),
  }) {
    final aiDataSource = FlutterFireAiLogicDataSource(firebase.ai);
    final aiRepository = FirebaseReadyAiRepository(aiDataSource);

    return AppDependencies(
      authRepository: FirebaseReadyAuthRepository(
        FlutterFireAuthDataSource(firebase.auth),
      ),
      storageRepository: FirebaseReadyStorageRepository(
        FlutterFireStorageDataSource(firebase.storage),
      ),
      petRepository: FirebasePetRepository(
        FlutterFirePetDataSource(firebase.firestore),
      ),
      ownerProfileRepository: FirebaseOwnerProfileRepository(
        firebase.firestore,
      ),
      weightEntryRepository: FirebaseWeightEntryRepository(
        firebase.firestore,
      ),
      timelineRepository: FirebaseTimelineRepository(
        FlutterFireTimelineDataSource(firebase.firestore),
      ),
      documentRepository: FirebaseDocumentRepository(
        FlutterFireDocumentDataSource(firebase.firestore),
      ),
      reminderRepository: FirebaseReminderRepository(
        FlutterFireReminderDataSource(firebase.firestore),
      ),
      aiRepository: aiRepository,
      smartInputRepository: FirebaseSmartInputRepository(
        aiRepository: aiRepository,
        dataSource: FlutterFireSmartInputDataSource(firebase.firestore),
      ),
      vetSummaryExportRepository: FirebaseVetSummaryExportRepository(
        FlutterFireVetSummaryExportDataSource(firebase.firestore),
      ),
      filePicker: const FilePickerImpl(),
      documentFileOpener: const UrlLauncherDocumentFileOpener(),
      documentExtractionAiRepository:
          FirebaseReadyDocumentExtractionAiRepository(aiDataSource),
      documentSourcePicker: DocumentSourcePickerImpl(),
      petPhotoPicker: PetPhotoPickerImpl(),
      eventPhotoPicker: EventPhotoPickerImpl(),
      reminderNotificationScheduler:
          LocalReminderNotificationScheduler(FlutterLocalNotificationsPlugin()),
      analyticsService: FirebaseAnalyticsService(firebase.analytics),
      subscriptionService: subscriptionService,
      paywallPresenter: paywallPresenter,
      trackingAuthorizationService: const AttTrackingAuthorizationService(),
      accountDeletionService: FirebaseAccountDeletionService(
        firebase.auth,
        firebase.firestore,
        firebase.storage,
      ),
    );
  }

  final AuthRepository authRepository;
  final StorageRepository storageRepository;
  final PetRepository petRepository;
  final TimelineRepository timelineRepository;
  final DocumentRepository documentRepository;
  final ReminderRepository reminderRepository;
  final AiRepository aiRepository;
  final SmartInputRepository smartInputRepository;
  final VetSummaryExportRepository vetSummaryExportRepository;
  final FilePicker filePicker;
  final DocumentFileOpener documentFileOpener;
  final DocumentExtractionAiRepository documentExtractionAiRepository;
  final DocumentSourcePicker documentSourcePicker;
  final PetPhotoPicker petPhotoPicker;
  final EventPhotoPicker eventPhotoPicker;
  final ReminderNotificationScheduler reminderNotificationScheduler;
  final AnalyticsService analyticsService;
  final SubscriptionService subscriptionService;
  final PaywallPresenter paywallPresenter;
  final TrackingAuthorizationService trackingAuthorizationService;
  final AccountDeletionService accountDeletionService;
  final OwnerProfileRepository ownerProfileRepository;
  final WeightEntryRepository weightEntryRepository;

  /// The auth repository also satisfies account (non-anonymous) auth.
  AccountAuthRepository get accountAuthRepository =>
      authRepository as AccountAuthRepository;

  LoadVetSummaryData get loadVetSummaryData => LoadVetSummaryData(
        petRepository: petRepository,
        timelineRepository: timelineRepository,
        documentRepository: documentRepository,
        reminderRepository: reminderRepository,
      );

  VetSummaryPdfGenerator get vetSummaryPdfGenerator =>
      const VetSummaryPdfBuilder();

  PdfShareService get pdfShareService => const PrintingPdfShareService();
}
