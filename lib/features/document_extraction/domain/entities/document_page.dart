import 'dart:typed_data';

/// One page/image of a document being analyzed.
class DocumentPage {
  const DocumentPage({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}
