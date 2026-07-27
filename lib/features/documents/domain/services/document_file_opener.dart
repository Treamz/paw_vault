/// Port for opening a stored document file (its download URL) outside the
/// app, e.g. in the browser or a system viewer.
///
/// Concrete implementations live in the data layer and wrap a platform
/// launcher; the presentation layer depends only on this abstraction.
abstract interface class DocumentFileOpener {
  /// Opens [fileUrl] externally. Returns `false` if the URL could not be
  /// opened.
  Future<bool> open(Uri fileUrl);
}
