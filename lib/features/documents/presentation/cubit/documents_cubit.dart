import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
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
            DocumentsState(
              status: DocumentsStatus.ready,
              userId: userId,
              petId: petId,
              documents: documents,
            ),
          );
        },
        onError: (Object error) {
          emit(
            DocumentsState(
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
    this.errorMessage,
  });

  final DocumentsStatus status;
  final EntityId? userId;
  final String? petId;
  final List<PetDocument> documents;
  final String? errorMessage;

  bool get isReady => status == DocumentsStatus.ready;
}
