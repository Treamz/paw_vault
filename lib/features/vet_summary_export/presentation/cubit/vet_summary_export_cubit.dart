import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/analytics/data/services/noop_analytics_service.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_events.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/core/firebase/storage/firebase_storage_paths.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/vet_summary_export/application/load_vet_summary_data.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_export.dart';
import 'package:paw_vault/features/vet_summary_export/domain/repositories/vet_summary_export_repository.dart';
import 'package:paw_vault/features/vet_summary_export/domain/services/pdf_share_service.dart';
import 'package:paw_vault/features/vet_summary_export/domain/services/vet_summary_pdf_generator.dart';

class VetSummaryExportCubit extends Cubit<VetSummaryExportState> {
  VetSummaryExportCubit({
    required AuthRepository authRepository,
    required LoadVetSummaryData loadVetSummaryData,
    required VetSummaryPdfGenerator pdfGenerator,
    required PdfShareService shareService,
    required StorageRepository storageRepository,
    required VetSummaryExportRepository exportRepository,
    AnalyticsService? analytics,
  })  : _authRepository = authRepository,
        _loadVetSummaryData = loadVetSummaryData,
        _pdfGenerator = pdfGenerator,
        _shareService = shareService,
        _storageRepository = storageRepository,
        _exportRepository = exportRepository,
        _analytics = analytics ?? const NoopAnalyticsService(),
        super(const VetSummaryExportState());

  final AuthRepository _authRepository;
  final LoadVetSummaryData _loadVetSummaryData;
  final VetSummaryPdfGenerator _pdfGenerator;
  final PdfShareService _shareService;
  final StorageRepository _storageRepository;
  final VetSummaryExportRepository _exportRepository;
  final AnalyticsService _analytics;
  StreamSubscription<List<VetSummaryExport>>? _exportsSubscription;

  /// Subscribes to the pet's saved export history.
  Future<void> load(String petId) async {
    emit(
      state.copyWith(
        petId: petId,
        historyStatus: VetSummaryHistoryStatus.loading,
      ),
    );

    try {
      await _exportRepository.initialize();
      final user = await _authRepository.currentUser() ??
          await _authRepository.signInAnonymously();
      final userId = EntityId(user.id);

      await _exportsSubscription?.cancel();
      _exportsSubscription = _exportRepository
          .watchExports(userId: userId, petId: EntityId(petId))
          .listen(
        (exports) {
          // Newest first. An export whose server timestamp is still pending
          // sorts to the top: it was just saved, so it is the newest thing
          // here even though its date is not known yet.
          final sorted = [...exports]..sort((a, b) {
              final aAt = a.createdAt?.value;
              final bAt = b.createdAt?.value;
              if (aAt == null || bAt == null) {
                return aAt == bAt ? 0 : (aAt == null ? -1 : 1);
              }
              return bAt.compareTo(aAt);
            });
          emit(
            state.copyWith(
              userId: userId,
              historyStatus: VetSummaryHistoryStatus.ready,
              exports: sorted,
            ),
          );
        },
        onError: (Object error) {
          // A failed refresh must not replace a list we already have. The
          // stream survives the error and the next snapshot re-emits, so
          // blanking the history here left the owner staring at red text
          // with no way back except leaving the screen and returning.
          if (state.exports.isNotEmpty) {
            return;
          }
          emit(
            state.copyWith(
              historyStatus: VetSummaryHistoryStatus.failure,
              historyError: error.toString(),
            ),
          );
        },
      );
    } catch (error) {
      emit(
        state.copyWith(
          historyStatus: VetSummaryHistoryStatus.failure,
          historyError: error.toString(),
        ),
      );
    }
  }

  /// Loads the pet's records and renders a PDF, held in state for review.
  Future<void> generate(String petId) async {
    emit(
      state.copyWith(
        status: VetSummaryExportStatus.generating,
        petId: petId,
        clearPdf: true,
        clearError: true,
      ),
    );

    try {
      final user = await _authRepository.currentUser() ??
          await _authRepository.signInAnonymously();
      final userId = EntityId(user.id);
      final data = await _loadVetSummaryData.call(
        userId: userId,
        petId: EntityId(petId),
      );
      final bytes = await _pdfGenerator.build(data);
      _analytics.logEvent(AnalyticsEvents.vetSummaryExported);

      emit(
        state.copyWith(
          status: VetSummaryExportStatus.ready,
          userId: userId,
          petId: petId,
          petName: data.pet.name,
          pdfBytes: bytes,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: VetSummaryExportStatus.failure,
          petId: petId,
          errorMessage: error.toString(),
          clearPdf: true,
        ),
      );
    }
  }

  /// Shares the generated PDF via the platform share sheet (which includes
  /// "Save to Files" for choosing a destination). [fileName] overrides the
  /// default pet-derived name.
  Future<void> share({String? fileName}) async {
    final bytes = state.pdfBytes;
    if (bytes == null) {
      emit(
        state.copyWith(
          status: VetSummaryExportStatus.failure,
          errorMessage: 'Generate a summary first.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: VetSummaryExportStatus.sharing));

    try {
      await _shareService.share(
        bytes: bytes,
        fileName: sanitizeFileName(fileName) ?? defaultFileName(),
      );
      emit(state.copyWith(status: VetSummaryExportStatus.ready));
    } catch (error) {
      emit(
        state.copyWith(
          status: VetSummaryExportStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Uploads the generated PDF to storage and records the export.
  ///
  /// [fileName] is what the export is called in the app afterwards; it is
  /// kept on the record because the storage object is named after the export
  /// id, so without it the saved copy has no name of its own.
  Future<void> saveCopy({String? fileName}) async {
    final bytes = state.pdfBytes;
    final userId = state.userId;
    final petId = state.petId;
    if (bytes == null || userId == null || petId == null) {
      emit(
        state.copyWith(
          status: VetSummaryExportStatus.failure,
          errorMessage: 'Generate a summary first.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: VetSummaryExportStatus.saving));

    try {
      final entityPetId = EntityId(petId);
      final now = DateTime.now();
      final exportId = EntityId('${now.microsecondsSinceEpoch}');
      final path = FirebaseStoragePaths.vetSummaryExport(
        userId: userId.value,
        petId: petId,
        exportId: exportId.value,
      );

      final uploaded = await _storageRepository.uploadBytes(
        path: path,
        bytes: bytes,
        contentType: 'application/pdf',
      );

      await _exportRepository.saveExport(
        VetSummaryExport(
          id: exportId,
          userId: userId,
          petId: entityPetId,
          createdAt: UtcDateTime(now),
          fileUrl: uploaded.downloadUrl,
          storagePath: uploaded.path,
          fileName: sanitizeFileName(fileName) ?? defaultFileName(),
        ),
      );

      emit(state.copyWith(status: VetSummaryExportStatus.saved));
    } catch (error) {
      emit(
        state.copyWith(
          status: VetSummaryExportStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Default export file name derived from the pet's name.
  String defaultFileName() {
    final name = (state.petName ?? 'pet').replaceAll(RegExp(r'\s+'), '_');
    return '${name}_vet_summary.pdf';
  }

  /// Normalizes a user-entered file name: trims, strips path separators, and
  /// ensures a `.pdf` extension. Returns null for blank input.
  static String? sanitizeFileName(String? name) {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final safe = trimmed.replaceAll(RegExp(r'[/\\:]'), '_');
    return safe.toLowerCase().endsWith('.pdf') ? safe : '$safe.pdf';
  }

  @override
  Future<void> close() async {
    await _exportsSubscription?.cancel();
    return super.close();
  }
}

enum VetSummaryExportStatus {
  idle,
  generating,
  ready,
  sharing,
  saving,
  saved,
  failure,
}

enum VetSummaryHistoryStatus {
  loading,
  ready,
  failure,
}

class VetSummaryExportState {
  const VetSummaryExportState({
    this.status = VetSummaryExportStatus.idle,
    this.userId,
    this.petId,
    this.petName,
    this.pdfBytes,
    this.errorMessage,
    this.historyStatus = VetSummaryHistoryStatus.loading,
    this.exports = const [],
    this.historyError,
  });

  final VetSummaryExportStatus status;
  final EntityId? userId;
  final String? petId;
  final String? petName;
  final Uint8List? pdfBytes;
  final String? errorMessage;
  final VetSummaryHistoryStatus historyStatus;
  final List<VetSummaryExport> exports;
  final String? historyError;

  bool get hasPdf => pdfBytes != null;

  VetSummaryExportState copyWith({
    VetSummaryExportStatus? status,
    EntityId? userId,
    String? petId,
    String? petName,
    Uint8List? pdfBytes,
    String? errorMessage,
    VetSummaryHistoryStatus? historyStatus,
    List<VetSummaryExport>? exports,
    String? historyError,
    bool clearPdf = false,
    bool clearError = false,
  }) {
    return VetSummaryExportState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      pdfBytes: clearPdf ? null : (pdfBytes ?? this.pdfBytes),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      historyStatus: historyStatus ?? this.historyStatus,
      exports: exports ?? this.exports,
      historyError: historyError ?? this.historyError,
    );
  }
}
