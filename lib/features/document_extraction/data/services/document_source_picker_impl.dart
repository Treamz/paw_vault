import 'package:file_picker/file_picker.dart' as fp;
import 'package:image_picker/image_picker.dart' hide PickedFile;
import 'package:paw_vault/features/document_extraction/domain/services/document_source_picker.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';

/// [DocumentSourcePicker] backed by `image_picker` (camera/gallery) and
/// `file_picker` (PDF/image files).
class DocumentSourcePickerImpl implements DocumentSourcePicker {
  DocumentSourcePickerImpl({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  static const _fileExtensions = <String>['pdf', 'jpg', 'jpeg', 'png'];

  @override
  Future<PickedFile?> pick(DocumentSource source) {
    return switch (source) {
      DocumentSource.camera => _pickImage(ImageSource.camera),
      DocumentSource.gallery => _pickImage(ImageSource.gallery),
      DocumentSource.file => _pickFile(),
    };
  }

  Future<PickedFile?> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(source: source);
    if (image == null) {
      return null;
    }

    final bytes = await image.readAsBytes();
    final extension = _extensionOf(image.name);

    return PickedFile(
      bytes: bytes,
      fileName: image.name,
      extension: extension,
      contentType: _contentTypeFor(extension),
    );
  }

  Future<PickedFile?> _pickFile() async {
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: _fileExtensions,
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

  String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) {
      return 'jpg';
    }
    return fileName.substring(dot + 1).toLowerCase();
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
