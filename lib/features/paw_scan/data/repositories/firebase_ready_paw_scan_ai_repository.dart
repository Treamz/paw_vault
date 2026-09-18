import 'package:paw_vault/core/ai/data/datasources/firebase_ai_logic_data_source.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_photo.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_scan_draft.dart';
import 'package:paw_vault/features/paw_scan/domain/repositories/paw_scan_ai_repository.dart';

class FirebaseReadyPawScanAiRepository implements PawScanAiRepository {
  const FirebaseReadyPawScanAiRepository(this._dataSource);

  final FirebaseAiLogicDataSource _dataSource;

  @override
  Future<PawScanDraft> analyzePaw({
    required List<PawPhoto> photos,
    required PawLocation location,
    String? speciesLabel,
  }) {
    return _dataSource.analyzePaw(
      photos: photos,
      location: location,
      speciesLabel: speciesLabel,
    );
  }
}
