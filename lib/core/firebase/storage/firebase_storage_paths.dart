abstract final class FirebaseStoragePaths {
  static String documentOriginal({
    required String userId,
    required String petId,
    required String documentId,
    required String extension,
  }) {
    return 'users/$userId/pets/$petId/documents/$documentId/original.$extension';
  }

  /// One object per attachment. [documentOriginal] writes a single
  /// `original.<ext>` per document, so a second file had physically nowhere to
  /// go — attaching two to one document silently kept one.
  static String documentAttachment({
    required String userId,
    required String petId,
    required String documentId,
    required int index,
    required String extension,
  }) {
    return 'users/$userId/pets/$petId/documents/$documentId/'
        'attachment_$index.$extension';
  }

  static String documentScan({
    required String userId,
    required String petId,
    required String documentId,
  }) {
    return 'users/$userId/pets/$petId/documents/$documentId/scan.jpg';
  }

  /// One object per photo. The picker always re-encodes to JPEG, so there is
  /// no extension to vary.
  static String pawCheckPhoto({
    required String userId,
    required String petId,
    required String checkId,
    required String photoId,
  }) {
    return 'users/$userId/pets/$petId/pawChecks/$checkId/$photoId.jpg';
  }

  static String profilePhoto({
    required String userId,
    required String petId,
  }) {
    return 'users/$userId/pets/$petId/photos/profile.jpg';
  }

  static String eventAttachment({
    required String userId,
    required String petId,
    required String eventId,
    required String attachmentId,
    required String extension,
  }) {
    return 'users/$userId/pets/$petId/events/$eventId/attachments/'
        '$attachmentId.$extension';
  }

  static String vetSummaryExport({
    required String userId,
    required String petId,
    required String exportId,
  }) {
    // One object per export: reusing a single path would rotate the download
    // token on every upload and break previously saved links (403).
    return 'users/$userId/pets/$petId/exports/vet_summary_$exportId.pdf';
  }
}
