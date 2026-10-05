import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/documents/domain/entities/document_attachment.dart';

enum PetDocumentType {
  passport,
  vaccinationCertificate,
  insurance,
  labResult,
  prescription,
  receipt,
  vetReport,
  other,
}

class PetDocument {
  const PetDocument({
    required this.id,
    required this.userId,
    required this.petId,
    required this.title,
    required this.type,
    this.fileUrl,
    this.storagePath,
    this.attachments = const [],
    this.extractedText,
    this.extractedData = const {},
    this.issueDate,
    this.expiryDate,
    this.notes,
    this.linkedEventId,
    this.createdAt,
    this.updatedAt,
  });

  final EntityId id;
  final EntityId userId;
  final EntityId petId;
  final String title;
  final PetDocumentType type;

  /// Download URL of the stored file; `null` when the document was saved
  /// without a file attachment.
  ///
  /// **Legacy single-file fields.** Documents saved before multi-attachment
  /// support carry their only file here and nothing in [attachments]. Read
  /// files through [files], which covers both shapes; these two exist so
  /// already-saved documents keep working.
  final Uri? fileUrl;
  final String? storagePath;

  /// Every file attached to this document, for documents saved with
  /// multi-attachment support. May be empty for a legacy document — use
  /// [files] rather than reading this directly.
  final List<DocumentAttachment> attachments;
  final String? extractedText;
  final Map<String, Object?> extractedData;
  final DateOnly? issueDate;
  final DateOnly? expiryDate;
  final String? notes;
  final EntityId? linkedEventId;
  final UtcDateTime? createdAt;
  final UtcDateTime? updatedAt;

  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'heic', 'webp'};

  /// Every attached file, whichever shape the document was saved in.
  ///
  /// This is the only thing the UI should read. [attachments] when it has
  /// them, otherwise the legacy [fileUrl]/[storagePath] pair promoted to a
  /// single-element list.
  List<DocumentAttachment> get files {
    if (attachments.isNotEmpty) {
      return attachments;
    }

    final url = fileUrl;
    final path = storagePath;
    if (url == null || path == null) {
      return const [];
    }

    return [DocumentAttachment(fileUrl: url, storagePath: path)];
  }

  /// Every storage path this document owns, so deleting it can clean up all
  /// of them rather than orphaning the extras.
  List<String> get storagePaths =>
      files.map((file) => file.storagePath).toList();

  /// Whether the document has at least one stored file attached.
  bool get hasFile => files.isNotEmpty;

  /// File extension (without dot, lowercase) derived from [storagePath];
  /// empty when there is no file or the path has no extension. The content
  /// type is not persisted, so this is how the stored file's kind is
  /// determined.
  String get fileExtension {
    final path = files.isEmpty ? storagePath : files.first.storagePath;
    if (path == null) {
      return '';
    }
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) {
      return '';
    }
    return path.substring(dot + 1).toLowerCase();
  }

  /// Whether the first stored file is an image that can be previewed inline.
  bool get hasImageFile => hasFile && _imageExtensions.contains(fileExtension);

  /// The attached files that can be previewed inline.
  List<DocumentAttachment> get imageFiles =>
      files.where((file) => file.isImage).toList();
}
