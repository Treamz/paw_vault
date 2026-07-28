import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/vet_summary_export/application/load_vet_summary_data.dart';
import 'package:paw_vault/features/vet_summary_export/domain/repositories/vet_summary_export_repository.dart';
import 'package:paw_vault/features/vet_summary_export/domain/services/pdf_share_service.dart';
import 'package:paw_vault/features/vet_summary_export/domain/services/vet_summary_pdf_generator.dart';
import 'package:paw_vault/features/vet_summary_export/presentation/cubit/vet_summary_export_cubit.dart';
import 'package:printing/printing.dart';

@RoutePage()
class VetSummaryExportScreen extends StatelessWidget {
  const VetSummaryExportScreen({
    @PathParam('petId') required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VetSummaryExportCubit(
        authRepository: context.read<AuthRepository>(),
        loadVetSummaryData: context.read<LoadVetSummaryData>(),
        pdfGenerator: context.read<VetSummaryPdfGenerator>(),
        shareService: context.read<PdfShareService>(),
        storageRepository: context.read<StorageRepository>(),
        exportRepository: context.read<VetSummaryExportRepository>(),
        analytics: context.read<AnalyticsService>(),
      )..load(petId),
      child: _VetSummaryView(petId: petId),
    );
  }
}

class _VetSummaryView extends StatefulWidget {
  const _VetSummaryView({required this.petId});

  final String petId;

  @override
  State<_VetSummaryView> createState() => _VetSummaryViewState();
}

class _VetSummaryViewState extends State<_VetSummaryView> {
  final _fileNameController = TextEditingController();

  String get petId => widget.petId;

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  void _openPreview(BuildContext context, Uint8List bytes, String fileName) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PdfPreviewScreen(bytes: bytes, fileName: fileName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vet Summary')),
      body: SafeArea(
        child: BlocConsumer<VetSummaryExportCubit, VetSummaryExportState>(
          listener: (context, state) {
            if (state.status == VetSummaryExportStatus.saved) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Summary saved to records')),
              );
            }
            if (state.status == VetSummaryExportStatus.failure &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
          },
          builder: (context, state) {
            final cubit = context.read<VetSummaryExportCubit>();
            final isGenerating =
                state.status == VetSummaryExportStatus.generating;
            final isSharing = state.status == VetSummaryExportStatus.sharing;
            final isSaving = state.status == VetSummaryExportStatus.saving;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Generate a PDF summary of this pet\'s profile, timeline, '
                  'documents, and reminders to share with your vet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: isGenerating ? null : () => cubit.generate(petId),
                  icon: isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(
                    isGenerating
                        ? 'Generating…'
                        : state.hasPdf
                            ? 'Regenerate'
                            : 'Generate summary',
                  ),
                ),
                if (state.hasPdf) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _fileNameController
                      ..text = _fileNameController.text.isEmpty
                          ? cubit.defaultFileName()
                          : _fileNameController.text,
                    decoration: const InputDecoration(
                      labelText: 'File name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _openPreview(
                      context,
                      state.pdfBytes!,
                      VetSummaryExportCubit.sanitizeFileName(
                            _fileNameController.text,
                          ) ??
                          cubit.defaultFileName(),
                    ),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Preview'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isSharing || isSaving
                              ? null
                              : () => cubit.share(
                                    fileName: _fileNameController.text,
                                  ),
                          icon: isSharing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed:
                              isSharing || isSaving ? null : cubit.saveCopy,
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: const Text('Save copy'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Saved exports',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _History(state: state),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.state});

  final VetSummaryExportState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMMd().add_jm();

    return switch (state.historyStatus) {
      VetSummaryHistoryStatus.loading => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      VetSummaryHistoryStatus.failure => Text(
          state.historyError ?? 'Could not load saved exports',
          style: TextStyle(color: theme.colorScheme.error),
        ),
      VetSummaryHistoryStatus.ready => state.exports.isEmpty
          ? Text('No saved exports yet.', style: theme.textTheme.bodyMedium)
          : Column(
              children: [
                for (final export in state.exports)
                  Card(
                    child: ListTile(
                      key: ValueKey('export-${export.id.value}'),
                      leading: const Icon(Icons.picture_as_pdf),
                      title: Text(dateFormat.format(export.createdAt.value)),
                      subtitle: const Text('Vet summary PDF'),
                    ),
                  ),
              ],
            ),
    };
  }
}

/// In-app viewer for the generated summary. The preview toolbar also offers
/// printing and sharing (which includes saving to a chosen location).
class _PdfPreviewScreen extends StatelessWidget {
  const _PdfPreviewScreen({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(fileName)),
      body: PdfPreview(
        build: (format) async => bytes,
        pdfFileName: fileName,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}
