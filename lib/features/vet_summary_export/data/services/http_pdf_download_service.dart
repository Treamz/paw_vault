import 'dart:io';
import 'dart:typed_data';

import 'package:paw_vault/features/vet_summary_export/domain/services/pdf_download_service.dart';

/// [PdfDownloadService] backed by `dart:io`'s [HttpClient]; storage download
/// URLs are token-authenticated, so a plain GET suffices.
class HttpPdfDownloadService implements PdfDownloadService {
  const HttpPdfDownloadService();

  @override
  Future<Uint8List> download(Uri url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(url);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Download failed with status ${response.statusCode}',
          uri: url,
        );
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } finally {
      client.close();
    }
  }
}
