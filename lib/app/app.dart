import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/app/router/app_router.dart';
import 'package:paw_vault/app/theme/app_theme.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/ai_repository.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/vet_summary_export/domain/repositories/vet_summary_export_repository.dart';

class PawVaultApp extends StatefulWidget {
  const PawVaultApp({
    required this.dependencies,
    super.key,
  });

  final AppDependencies dependencies;

  @override
  State<PawVaultApp> createState() => _PawVaultAppState();
}

class _PawVaultAppState extends State<PawVaultApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(
          value: widget.dependencies.authRepository,
        ),
        RepositoryProvider<StorageRepository>.value(
          value: widget.dependencies.storageRepository,
        ),
        RepositoryProvider<PetRepository>.value(
          value: widget.dependencies.petRepository,
        ),
        RepositoryProvider<TimelineRepository>.value(
          value: widget.dependencies.timelineRepository,
        ),
        RepositoryProvider<DocumentRepository>.value(
          value: widget.dependencies.documentRepository,
        ),
        RepositoryProvider<ReminderRepository>.value(
          value: widget.dependencies.reminderRepository,
        ),
        RepositoryProvider<AiRepository>.value(
          value: widget.dependencies.aiRepository,
        ),
        RepositoryProvider<SmartInputRepository>.value(
          value: widget.dependencies.smartInputRepository,
        ),
        RepositoryProvider<VetSummaryExportRepository>.value(
          value: widget.dependencies.vetSummaryExportRepository,
        ),
      ],
      child: MaterialApp.router(
        title: 'PawVault',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: _appRouter.config(),
      ),
    );
  }
}
