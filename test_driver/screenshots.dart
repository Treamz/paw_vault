// Driver for the screenshot suite. Receives each screenshot's PNG bytes from
// integration_test/screenshots_test.dart and writes them to disk.
//
// The output directory is taken from the SCREENSHOT_DIR environment variable
// (set per device by tool/screenshots.sh); it defaults to build/screenshots.
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final outputDir =
      Platform.environment['SCREENSHOT_DIR'] ?? 'build/screenshots';
  await integrationDriver(
    onScreenshot: (
      String name,
      List<int> bytes, [
      Map<String, Object?>? args,
    ]) async {
      final file = File('$outputDir/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      stdout.writeln('Saved ${file.path} (${bytes.length} bytes)');
      return true;
    },
  );
}
