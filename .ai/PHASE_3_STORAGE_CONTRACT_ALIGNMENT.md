# Phase 3 Storage Contract Alignment

## Scope

Confirmed that the existing `StorageRepository` contract aligns with PawVault's
Firebase Storage use cases for pet photos, documents, document scans, and vet
summary exports. No API changes were needed.

## Contract

Current contract:

```text
StorageRepository.uploadBytes({
  required String path,
  required Uint8List bytes,
  required String contentType,
})

StorageRepository.delete(String path)
```

This supports the MVP use cases because feature flows can:

- generate deterministic Firebase Storage paths with `FirebaseStoragePaths`
- upload raw bytes with an explicit content type
- persist `StorageFile.downloadUrl` as `photoUrl` or `fileUrl`
- persist `StorageFile.path` as `storagePath` where replacement/deletion is
  needed
- delete later using the stored `storagePath`

## Path Coverage

Existing path helpers cover:

- pet profile photos:
  `users/{userId}/pets/{petId}/photos/profile.jpg`
- document originals:
  `users/{userId}/pets/{petId}/documents/{documentId}/original.{extension}`
- document scans:
  `users/{userId}/pets/{petId}/documents/{documentId}/scan.jpg`
- vet summary exports:
  `users/{userId}/pets/{petId}/exports/vet_summary.pdf`

## Notes

Document metadata currently stores both `fileUrl` and `storagePath`.
Vet summary exports optionally store both `fileUrl` and `storagePath`.
Pet profile photos currently store only `photoUrl`; if photo replacement/delete
needs exact storage cleanup later, either the deterministic profile photo path
can be regenerated or a `photoStoragePath` field can be added in a later phase.
