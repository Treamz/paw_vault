import 'package:flutter/material.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/app/bootstrap/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await AppBootstrap.createDependencies();

  runApp(
    PawVaultApp(
      dependencies: dependencies,
    ),
  );
}
