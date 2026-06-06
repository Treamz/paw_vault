import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';

class DocumentsCubit extends Cubit<DocumentsState> {
  DocumentsCubit(this._documentRepository) : super(const DocumentsState());

  final DocumentRepository _documentRepository;

  Future<void> load(String petId) async {
    await _documentRepository.initialize();
    emit(DocumentsState(petId: petId, isReady: true));
  }
}

class DocumentsState {
  const DocumentsState({
    this.petId,
    this.isReady = false,
  });

  final String? petId;
  final bool isReady;
}
