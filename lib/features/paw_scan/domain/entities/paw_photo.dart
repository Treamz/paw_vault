import 'dart:typed_data';

/// A single paw photograph handed to the AI port for analysis.
///
/// Deliberately separate from the picked file: analysis only needs the bytes
/// and the MIME type, and the photo is not uploaded unless the owner confirms
/// the resulting check.
class PawPhoto {
  const PawPhoto({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}
