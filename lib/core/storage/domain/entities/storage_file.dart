class StorageFile {
  const StorageFile({
    required this.path,
    required this.downloadUrl,
  });

  final String path;
  final Uri downloadUrl;
}
