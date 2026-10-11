/// One file stored against a [PetDocument].
///
/// A document can carry several — a scan of a multi-page certificate, or a
/// photo of the original alongside a screenshot of the email it arrived in.
class DocumentAttachment {
  const DocumentAttachment({required this.fileUrl, required this.storagePath});

  final Uri fileUrl;
  final String storagePath;

  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'heic', 'webp'};

  /// Extension without the dot, lowercased; empty when the path has none.
  ///
  /// Derived from [storagePath] because the content type is not persisted.
  String get fileExtension {
    final dot = storagePath.lastIndexOf('.');
    if (dot == -1 || dot == storagePath.length - 1) {
      return '';
    }
    return storagePath.substring(dot + 1).toLowerCase();
  }

  /// Whether this file can be previewed inline.
  bool get isImage => _imageExtensions.contains(fileExtension);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DocumentAttachment &&
            runtimeType == other.runtimeType &&
            fileUrl == other.fileUrl &&
            storagePath == other.storagePath;
  }

  @override
  int get hashCode => Object.hash(fileUrl, storagePath);

  @override
  String toString() => 'DocumentAttachment($storagePath)';
}
