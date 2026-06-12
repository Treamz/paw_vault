import 'dart:typed_data';

/// Port for sharing generated PDF bytes via the platform share sheet.
abstract interface class PdfShareService {
  Future<void> share({
    required Uint8List bytes,
    required String fileName,
  });
}
