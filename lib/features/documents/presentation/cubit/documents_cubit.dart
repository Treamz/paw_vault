import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';

class DocumentsCubit extends Cubit<DocumentsState> {
  DocumentsCubit({
    required DocumentRepository documentRepository,
    required AuthRepository authRepository,
  })  : _documentRepository = documentRepository,
        _authRepository = authRepository,
        super(const DocumentsState());

  final DocumentRepository _documentRepository;
  final AuthRepository _authRepository;
  StreamSubscription<List<PetDocument>>? _documentsSubscription;

  Future<void> load(String petId) async {
    emit(DocumentsState(status: DocumentsStatus.loading, petId: petId));

    try {
      await _documentRepository.initialize();
      final user = await _authRepository.currentUser() ??
          await _authRepository.signInAnonymously();
      final userId = EntityId(user.id);
      final entityPetId = EntityId(petId);

      await _documentsSubscription?.cancel();
      _documentsSubscription = _documentRepository
          .watchDocuments(userId: userId, petId: entityPetId)
          .listen(
        (documents) {
          emit(
            state.copyWith(
              status: DocumentsStatus.ready,
              userId: userId,
              petId: petId,
              // Newest first by the document's own date, so scanned files
              // slot in by their issue date rather than when they synced.
              documents: [...documents]..sort((a, b) {
                  final aTime = a.issueDate?.toUtcDateTime() ??
                      a.createdAt?.value ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  final bTime = b.issueDate?.toUtcDateTime() ??
                      b.createdAt?.value ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  return bTime.compareTo(aTime);
                }),
            ),
          );
        },
        onError: (Object error) {
          emit(
            state.copyWith(
              status: DocumentsStatus.failure,
              userId: userId,
              petId: petId,
              errorMessage: error.toString(),
            ),
          );
        },
      );
    } catch (error) {
      emit(
        DocumentsState(
          status: DocumentsStatus.failure,
          petId: petId,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void setTypeFilter(PetDocumentType? type) {
    emit(
      state.copyWith(
        filterType: type,
        clearTypeFilter: type == null,
      ),
    );
  }

  /// Shows only documents whose expiry date is on or before [cutoff].
  ///
  /// The UI supplies the cutoff (e.g. `DateTime.now().add(Duration(days: 30))`
  /// for an "expiring soon" view) so the cubit stays time-independent.
  void setExpiringBeforeFilter(DateTime? cutoff) {
    emit(
      state.copyWith(
        expiringBefore: cutoff,
        clearExpiringBefore: cutoff == null,
      ),
    );
  }

  void clearFilters() {
    emit(
      state.copyWith(
        clearTypeFilter: true,
        clearExpiringBefore: true,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _documentsSubscription?.cancel();
    return super.close();
  }
}

enum DocumentsStatus {
  initial,
  loading,
  ready,
  failure,
}

class DocumentsState {
  const DocumentsState({
    this.status = DocumentsStatus.initial,
    this.userId,
    this.petId,
    this.documents = const [],
    this.filterType,
    this.expiringBefore,
    this.errorMessage,
  });

  final DocumentsStatus status;
  final EntityId? userId;
  final String? petId;
  final List<PetDocument> documents;
  final PetDocumentType? filterType;
  final DateTime? expiringBefore;
  final String? errorMessage;

  bool get isReady => status == DocumentsStatus.ready;

  List<PetDocument> get filteredDocuments {
    var filtered = documents;

    if (filterType != null) {
      filtered =
          filtered.where((document) => document.type == filterType).toList();
    }

    if (expiringBefore != null) {
      final cutoff = DateOnly.fromDateTime(expiringBefore!);
      filtered = filtered.where((document) {
        final expiry = document.expiryDate;
        return expiry != null && expiry.compareTo(cutoff) <= 0;
      }).toList();
    }

    return filtered;
  }

  DocumentsState copyWith({
    DocumentsStatus? status,
    EntityId? userId,
    String? petId,
    List<PetDocument>? documents,
    PetDocumentType? filterType,
    DateTime? expiringBefore,
    String? errorMessage,
    bool clearTypeFilter = false,
    bool clearExpiringBefore = false,
  }) {
    return DocumentsState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      documents: documents ?? this.documents,
      filterType: clearTypeFilter ? null : (filterType ?? this.filterType),
      expiringBefore:
          clearExpiringBefore ? null : (expiringBefore ?? this.expiringBefore),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
