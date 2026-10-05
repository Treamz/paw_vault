import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/features/documents/domain/entities/document_attachment.dart';

/// Shared serialization for [DocumentAttachment].
///
/// Both documents and the Smart Input history store attachment lists, and the
/// shape has to stay identical between them — a scanned document writes the
/// same files to both places.
abstract final class DocumentAttachmentFirestoreMapper {
  static Map<String, Object?> toFirestore(DocumentAttachment attachment) {
    return {
      'fileUrl': FirestoreMapping.uriToJson(attachment.fileUrl),
      'storagePath': attachment.storagePath,
    };
  }

  static List<Map<String, Object?>> listToFirestore(
    List<DocumentAttachment> attachments,
  ) {
    return attachments.map(toFirestore).toList();
  }

  /// Reads an attachment list. Absent is an empty list rather than an error:
  /// documents saved before multi-attachment support have no such field, and
  /// a typed Smart Input entry never has attachments at all.
  static List<DocumentAttachment> listFromFirestore(
    Object? value, {
    String fieldName = 'attachments',
  }) {
    if (value == null) {
      return const [];
    }

    if (value is! List) {
      throw FirestoreMappingException.expectedType(
        fieldName: fieldName,
        expectedType: 'List',
        actualValue: value,
      );
    }

    return value
        .map((entry) => _fromFirestore(entry, fieldName))
        .toList(growable: false);
  }

  static DocumentAttachment _fromFirestore(Object? value, String fieldName) {
    if (value is! Map) {
      throw FirestoreMappingException.expectedType(
        fieldName: fieldName,
        expectedType: 'Map',
        actualValue: value,
      );
    }

    final storagePath = value['storagePath'];
    if (storagePath is! String) {
      throw FirestoreMappingException.expectedType(
        fieldName: '$fieldName.storagePath',
        expectedType: 'String',
        actualValue: storagePath,
      );
    }

    return DocumentAttachment(
      fileUrl: FirestoreMapping.uriFromJson(
        value['fileUrl'],
        '$fieldName.fileUrl',
      ),
      storagePath: storagePath,
    );
  }
}
