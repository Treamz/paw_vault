import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/app/bootstrap/app_bootstrap.dart';

/// Instrumented entrypoint for Flutter Driver / MCP `flutter_driver_command`.
///
/// Run with: `flutter run -t test_driver/app.dart -d <device-id>`
/// This mirrors `lib/main.dart` but enables the driver extension so the app
/// can be driven (tap, enter_text, screenshot) for end-to-end verification.
Future<void> main() async {
  enableFlutterDriverExtension();
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await AppBootstrap.createDependencies();

  runApp(
    PawVaultApp(
      dependencies: dependencies,
    ),
  );
}
