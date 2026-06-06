import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/features/vet_summary_export/domain/repositories/vet_summary_export_repository.dart';

class VetSummaryExportCubit extends Cubit<VetSummaryExportState> {
  VetSummaryExportCubit(this._vetSummaryExportRepository)
      : super(const VetSummaryExportState());

  final VetSummaryExportRepository _vetSummaryExportRepository;

  Future<void> load(String petId) async {
    await _vetSummaryExportRepository.initialize();
    emit(VetSummaryExportState(petId: petId, isReady: true));
  }
}

class VetSummaryExportState {
  const VetSummaryExportState({
    this.petId,
    this.isReady = false,
  });

  final String? petId;
  final bool isReady;
}
