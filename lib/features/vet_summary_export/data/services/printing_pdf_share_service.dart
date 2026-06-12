import 'dart:typed_data';

import 'package:paw_vault/features/vet_summary_export/domain/services/pdf_share_service.dart';
import 'package:printing/printing.dart';

/// [PdfShareService] backed by the `printing` package's share sheet.
class PrintingPdfShareService implements PdfShareService {
  const PrintingPdfShareService();

  @override
  Future<void> share({
    required Uint8List bytes,
    required String fileName,
  }) async {
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}
