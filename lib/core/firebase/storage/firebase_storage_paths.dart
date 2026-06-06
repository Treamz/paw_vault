abstract final class FirebaseStoragePaths {
  static String documentOriginal({
    required String userId,
    required String petId,
    required String documentId,
    required String extension,
  }) {
    return 'users/$userId/pets/$petId/documents/$documentId/original.$extension';
  }

  static String documentScan({
    required String userId,
    required String petId,
    required String documentId,
  }) {
    return 'users/$userId/pets/$petId/documents/$documentId/scan.jpg';
  }

  static String profilePhoto({
    required String userId,
    required String petId,
  }) {
    return 'users/$userId/pets/$petId/photos/profile.jpg';
  }

  static String vetSummaryExport({
    required String userId,
    required String petId,
  }) {
    return 'users/$userId/pets/$petId/exports/vet_summary.pdf';
  }
}
