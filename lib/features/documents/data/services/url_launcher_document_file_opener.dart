import 'package:paw_vault/features/documents/domain/services/document_file_opener.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

/// [DocumentFileOpener] backed by `url_launcher`; opens the file's download
/// URL in the system browser/viewer.
class UrlLauncherDocumentFileOpener implements DocumentFileOpener {
  const UrlLauncherDocumentFileOpener();

  @override
  Future<bool> open(Uri fileUrl) async {
    if (!await launcher.canLaunchUrl(fileUrl)) {
      return false;
    }
    return launcher.launchUrl(
      fileUrl,
      mode: launcher.LaunchMode.externalApplication,
    );
  }
}
