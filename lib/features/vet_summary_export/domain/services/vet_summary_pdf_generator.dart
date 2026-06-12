import 'dart:typed_data';

import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_data.dart';

/// Port for rendering a [VetSummaryData] snapshot into PDF bytes.
abstract interface class VetSummaryPdfGenerator {
  Future<Uint8List> build(VetSummaryData data);
}
