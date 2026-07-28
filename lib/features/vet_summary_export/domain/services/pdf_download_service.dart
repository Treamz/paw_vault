import 'dart:typed_data';

/// Port for fetching a previously exported PDF from its download URL.
///
/// Concrete implementations live in the data layer; the presentation layer
/// depends only on this abstraction.
abstract interface class PdfDownloadService {
  /// Downloads the PDF at [url] and returns its bytes. Throws on failure.
  Future<Uint8List> download(Uri url);
}
