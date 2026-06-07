import 'package:paw_vault/core/ai/data/datasources/flutter_fire_ai_logic_data_source.dart';
import 'package:paw_vault/core/ai/data/datasources/noop_firebase_ai_logic_data_source.dart';
import 'package:paw_vault/core/auth/data/datasources/flutter_fire_auth_data_source.dart';
import 'package:paw_vault/core/auth/data/datasources/noop_firebase_auth_data_source.dart';
import 'package:paw_vault/core/auth/data/repositories/firebase_ready_auth_repository.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/firebase/firebase_instances.dart';
import 'package:paw_vault/core/storage/data/datasources/flutter_fire_storage_data_source.dart';
import 'package:paw_vault/core/storage/data/datasources/noop_firebase_storage_data_source.dart';
import 'package:paw_vault/core/storage/data/repositories/firebase_ready_storage_repository.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/documents/data/datasources/flutter_fire_document_data_source.dart';
import 'package:paw_vault/features/documents/data/repositories/firebase_document_repository.dart';
import 'package:paw_vault/features/documents/data/repositories/local_document_repository.dart';
import 'package:paw_vault/features/documents/data/services/file_picker_impl.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/pets/data/datasources/flutter_fire_pet_data_source.dart';
import 'package:paw_vault/features/pets/data/repositories/firebase_pet_repository.dart';
import 'package:paw_vault/features/pets/data/repositories/local_pet_repository.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/reminders/data/datasources/flutter_fire_reminder_data_source.dart';
import 'package:paw_vault/features/reminders/data/repositories/firebase_reminder_repository.dart';
import 'package:paw_vault/features/reminders/data/repositories/local_reminder_repository.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/smart_input/data/datasources/flutter_fire_smart_input_data_source.dart';
import 'package:paw_vault/features/smart_input/data/repositories/firebase_ready_ai_repository.dart';
import 'package:paw_vault/features/smart_input/data/repositories/firebase_smart_input_repository.dart';
import 'package:paw_vault/features/smart_input/data/repositories/noop_smart_input_repository.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/ai_repository.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';
import 'package:paw_vault/features/timeline/data/datasources/flutter_fire_timeline_data_source.dart';
import 'package:paw_vault/features/timeline/data/repositories/firebase_timeline_repository.dart';
import 'package:paw_vault/features/timeline/data/repositories/local_timeline_repository.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/vet_summary_export/data/datasources/flutter_fire_vet_summary_export_data_source.dart';
import 'package:paw_vault/features/vet_summary_export/data/repositories/firebase_vet_summary_export_repository.dart';
import 'package:paw_vault/features/vet_summary_export/data/repositories/local_vet_summary_export_repository.dart';
import 'package:paw_vault/features/vet_summary_export/domain/repositories/vet_summary_export_repository.dart';

class AppDependencies {
  const AppDependencies({
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
  });

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
    );
  }

  factory AppDependencies.firebaseReady(FirebaseInstances firebase) {
    final aiRepository = FirebaseReadyAiRepository(
      FlutterFireAiLogicDataSource(firebase.ai),
    );

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
}
