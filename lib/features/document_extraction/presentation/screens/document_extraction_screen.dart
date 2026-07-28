import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/document_extraction/domain/repositories/document_extraction_ai_repository.dart';
import 'package:paw_vault/features/document_extraction/domain/services/document_source_picker.dart';
import 'package:paw_vault/features/document_extraction/presentation/cubit/document_extraction_cubit.dart';
import 'package:paw_vault/features/documents/application/document_upload_service.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/documents/presentation/models/pet_document_form_state.dart';

@RoutePage()
class DocumentExtractionScreen extends StatelessWidget {
  const DocumentExtractionScreen({
    @PathParam('petId') required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DocumentExtractionCubit(
        picker: context.read<DocumentSourcePicker>(),
        aiRepository: context.read<DocumentExtractionAiRepository>(),
        authRepository: context.read<AuthRepository>(),
        documentRepository: context.read<DocumentRepository>(),
        uploadService: DocumentUploadService(
          filePicker: context.read<FilePicker>(),
          storageRepository: context.read<StorageRepository>(),
        ),
      ),
      child: _ExtractionView(petId: petId),
    );
  }
}

class _ExtractionView extends StatefulWidget {
  const _ExtractionView({required this.petId});

  final String petId;

  @override
  State<_ExtractionView> createState() => _ExtractionViewState();
}

class _ExtractionViewState extends State<_ExtractionView> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  PetDocumentType? _selectedType;
  DateTime? _issueDate;
  DateTime? _expiryDate;
  bool _seeded = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _seedFrom(DocumentExtractionDraft draft) {
    setState(() {
      _seeded = true;
      _selectedType = draft.detectedType;
      _titleController.text = draft.title ?? '';
      _notesController.text = draft.notes ?? '';
      _issueDate = draft.issueDate?.toUtcDateTime();
      _expiryDate = draft.expiryDate?.toUtcDateTime();
    });
  }

  PetDocumentFormState _buildFormState() {
    return PetDocumentFormState(
      type: _selectedType,
      title: _titleController.text,
      issueDate: _issueDate,
      expiryDate: _expiryDate,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );
  }

  void _confirm(BuildContext context) {
    final formState = _buildFormState();
    if (!formState.validate().isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors')),
      );
      return;
    }
    context.read<DocumentExtractionCubit>().confirmExtraction(
          widget.petId,
          formState,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Document')),
      body: SafeArea(
        child: BlocConsumer<DocumentExtractionCubit, DocumentExtractionState>(
          listener: (context, state) {
            if (state.status == DocumentExtractionStatus.review &&
                state.draft != null &&
                !_seeded) {
              _seedFrom(state.draft!);
            }

            if (state.status == DocumentExtractionStatus.confirmed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document saved')),
              );
              context.router.maybePop();
            }

            if (state.status == DocumentExtractionStatus.failure &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
          },
          builder: (context, state) {
            return switch (state.status) {
              DocumentExtractionStatus.picking ||
              DocumentExtractionStatus.extracting =>
                _Busy(
                  label: state.status == DocumentExtractionStatus.picking
                      ? 'Opening…'
                      : 'Reading document…',
                ),
              DocumentExtractionStatus.review ||
              DocumentExtractionStatus.saving =>
                _ReviewForm(
                  draft: state.draft,
                  titleController: _titleController,
                  notesController: _notesController,
                  selectedType: _selectedType,
                  issueDate: _issueDate,
                  expiryDate: _expiryDate,
                  isSaving: state.status == DocumentExtractionStatus.saving,
                  onTypeChanged: (value) =>
                      setState(() => _selectedType = value),
                  onPickIssueDate: _pickIssueDate,
                  onPickExpiryDate: _pickExpiryDate,
                  onConfirm: () => _confirm(context),
                ),
              _ => _SourcePicker(
                  onPick: (source) => context
                      .read<DocumentExtractionCubit>()
                      .pickAndExtract(source),
                ),
            };
          },
        ),
      ),
    );
  }

  Future<void> _pickIssueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDate: _issueDate ?? now,
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _issueDate = picked);
    }
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDate: _expiryDate ?? _issueDate ?? now,
      firstDate: _issueDate ?? DateTime(now.year - 100),
      lastDate: DateTime(now.year + 100),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }
}

class _SourcePicker extends StatelessWidget {
  const _SourcePicker({required this.onPick});

  final void Function(DocumentSource source) onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add a document by photo or file. The AI will read it and pre-fill '
            'the details for you to review before saving.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => onPick(DocumentSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take a photo'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => onPick(DocumentSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Choose from gallery'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => onPick(DocumentSource.file),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Pick a PDF or image'),
          ),
        ],
      ),
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label),
        ],
      ),
    );
  }
}

class _ReviewForm extends StatelessWidget {
  const _ReviewForm({
    required this.draft,
    required this.titleController,
    required this.notesController,
    required this.selectedType,
    required this.issueDate,
    required this.expiryDate,
    required this.isSaving,
    required this.onTypeChanged,
    required this.onPickIssueDate,
    required this.onPickExpiryDate,
    required this.onConfirm,
  });

  final DocumentExtractionDraft? draft;
  final TextEditingController titleController;
  final TextEditingController notesController;
  final PetDocumentType? selectedType;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final bool isSaving;
  final ValueChanged<PetDocumentType?> onTypeChanged;
  final VoidCallback onPickIssueDate;
  final VoidCallback onPickExpiryDate;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();

    return AbsorbPointer(
      absorbing: isSaving,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'AI-generated from your file. Review and edit the details '
                  '— nothing is saved until you confirm.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),
            if (draft?.isLowConfidence ?? false) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 18,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Low confidence — please double-check every field.',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<PetDocumentType>(
              initialValue: selectedType,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final type in PetDocumentType.values)
                  DropdownMenuItem(value: type, child: Text(_formatType(type))),
              ],
              onChanged: onTypeChanged,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Issue date (optional)'),
              subtitle: Text(
                issueDate != null ? dateFormat.format(issueDate!) : 'Not set',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: onPickIssueDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiry date (optional)'),
              subtitle: Text(
                expiryDate != null ? dateFormat.format(expiryDate!) : 'Not set',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: onPickExpiryDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: isSaving ? null : onConfirm,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(isSaving ? 'Saving…' : 'Confirm & save'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatType(PetDocumentType type) {
    return switch (type) {
      PetDocumentType.passport => 'Passport',
      PetDocumentType.vaccinationCertificate => 'Vaccination Certificate',
      PetDocumentType.insurance => 'Insurance',
      PetDocumentType.labResult => 'Lab Result',
      PetDocumentType.prescription => 'Prescription',
      PetDocumentType.receipt => 'Receipt',
      PetDocumentType.vetReport => 'Vet Report',
      PetDocumentType.other => 'Other',
    };
  }
}
