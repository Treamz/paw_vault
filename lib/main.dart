import 'package:flutter/material.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    PawVaultApp(
      dependencies: AppDependencies.localFirst(),
    ),
  );
}
