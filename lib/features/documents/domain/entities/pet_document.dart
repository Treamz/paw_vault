import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';

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
    required this.fileUrl,
    required this.storagePath,
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
  final Uri fileUrl;
  final String storagePath;
  final String? extractedText;
  final Map<String, Object?> extractedData;
  final DateOnly? issueDate;
  final DateOnly? expiryDate;
  final String? notes;
  final EntityId? linkedEventId;
  final UtcDateTime? createdAt;
  final UtcDateTime? updatedAt;

  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'heic', 'webp'};

  /// File extension (without dot, lowercase) derived from [storagePath];
  /// empty when the path has none. The content type is not persisted, so
  /// this is how the stored file's kind is determined.
  String get fileExtension {
    final dot = storagePath.lastIndexOf('.');
    if (dot == -1 || dot == storagePath.length - 1) {
      return '';
    }
    return storagePath.substring(dot + 1).toLowerCase();
  }

  /// Whether the stored file is an image that can be previewed inline.
  bool get hasImageFile => _imageExtensions.contains(fileExtension);
}
