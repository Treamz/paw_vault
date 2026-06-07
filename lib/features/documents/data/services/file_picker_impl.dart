import 'package:file_picker/file_picker.dart' as fp;
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';

/// [FilePicker] implementation backed by the `file_picker` plugin.
class FilePickerImpl implements FilePicker {
  const FilePickerImpl();

  static const _allowedExtensions = <String>[
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'heic',
    'webp',
  ];

  @override
  Future<PickedFile?> pickDocument() async {
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      return null;
    }

    final extension = (file.extension ?? '').toLowerCase();

    return PickedFile(
      bytes: bytes,
      fileName: file.name,
      extension: extension,
      contentType: _contentTypeFor(extension),
    );
  }

  String _contentTypeFor(String extension) {
    return switch (extension) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'heic' => 'image/heic',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }
}
