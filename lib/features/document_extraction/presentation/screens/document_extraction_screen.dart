import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/presentation/widgets/adaptive_body.dart';
import 'package:paw_vault/core/presentation/widgets/full_screen_image.dart';
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
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';
import 'package:printing/printing.dart';

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
        smartInputRepository: context.read<SmartInputRepository>(),
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

  /// Field errors from the last attempt to confirm.
  ///
  /// The scan rarely finds an issue date, and the date is required, so a bare
  /// "Please fix validation errors" left no clue which field was at fault.
  PetDocumentFormValidation? _validation;

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
    final validation = formState.validate();
    if (!validation.isValid) {
      setState(() => _validation = validation);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors')),
      );
      return;
    }
    setState(() => _validation = null);
    context.read<DocumentExtractionCubit>().confirmExtraction(
          widget.petId,
          formState,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Document')),
      body: AdaptiveBody(
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
                  pickedFiles: state.pickedFiles,
                  onAddPage: () => _addPage(context),
                  titleController: _titleController,
                  notesController: _notesController,
                  selectedType: _selectedType,
                  issueDate: _issueDate,
                  issueDateError: _validation?.errorFor('issueDate'),
                  typeError: _validation?.errorFor('type'),
                  titleError: _validation?.errorFor('title'),
                  expiryDate: _expiryDate,
                  onClearExpiryDate: _clearExpiryDate,
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

  Future<void> _addPage(BuildContext context) async {
    final cubit = context.read<DocumentExtractionCubit>();
    final source = await showModalBottomSheet<DocumentSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(DocumentSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(DocumentSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Pick a PDF or image'),
              onTap: () => Navigator.of(sheetContext).pop(DocumentSource.file),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    // Re-seed the form from the refreshed draft that covers every page.
    _seeded = false;
    await cubit.pickAndExtract(source);
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
      setState(() {
        _issueDate = picked;
        // Re-validate rather than clearing: another field may still be at
        // fault, and its error should stay on screen.
        if (_validation != null) {
          _validation = _buildFormState().validate();
        }
      });
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
      setState(() {
        _expiryDate = picked;
        // An expiry before the issue date is a validation error, so refresh
        // it the same way picking an issue date does.
        if (_validation != null) {
          _validation = _buildFormState().validate();
        }
      });
    }
  }

  void _clearExpiryDate() {
    setState(() {
      _expiryDate = null;
      if (_validation != null) {
        _validation = _buildFormState().validate();
      }
    });
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

/// Thumbnails of the files attached to this analysis, before anything is
/// saved.
///
/// The review form used to state only how many pages were attached, which is
/// no help when you have forgotten which photo you picked. These read from
/// the picked bytes, so nothing has to be uploaded first.
class _AttachedPages extends StatelessWidget {
  const _AttachedPages({required this.files});

  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'heic', 'webp'};

  final List<PickedFile> files;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        separatorBuilder: (context, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _AttachedPageThumbnail(
          file: files[index],
          pageNumber: index + 1,
          isImage:
              _imageExtensions.contains(files[index].extension.toLowerCase()),
        ),
      ),
    );
  }
}

class _AttachedPageThumbnail extends StatelessWidget {
  const _AttachedPageThumbnail({
    required this.file,
    required this.pageNumber,
    required this.isImage,
  });

  final PickedFile file;
  final int pageNumber;
  final bool isImage;

  void _open(BuildContext context) {
    if (isImage) {
      showFullScreenImage(context, MemoryImage(file.bytes));
      return;
    }

    if (file.extension.toLowerCase() == 'pdf') {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => _PickedPdfPreviewScreen(file: file),
        ),
      );
      return;
    }

    // Anything else has no in-app viewer; say so rather than doing nothing.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'No preview for ${file.extension.isEmpty ? 'this file' : '.${file.extension}'} files',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Page $pageNumber, ${file.fileName}',
      child: Tooltip(
        message: file.fileName,
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 96,
              height: 96,
              child: isImage
                  ? Image.memory(
                      file.bytes,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => _FileTile(
                        extension: file.extension,
                        broken: true,
                      ),
                    )
                  : _FileTile(extension: file.extension),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stands in for a file that cannot be shown as an image.
class _FileTile extends StatelessWidget {
  const _FileTile({required this.extension, this.broken = false});

  final String extension;
  final bool broken;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            broken
                ? Icons.broken_image_outlined
                : Icons.insert_drive_file_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          if (extension.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              extension.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// In-app viewer for a PDF that has been picked but not uploaded yet.
class _PickedPdfPreviewScreen extends StatelessWidget {
  const _PickedPdfPreviewScreen({required this.file});

  final PickedFile file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(file.fileName)),
      body: PdfPreview(
        build: (format) async => file.bytes,
        pdfFileName: file.fileName,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}

class _ReviewForm extends StatelessWidget {
  const _ReviewForm({
    required this.draft,
    required this.pickedFiles,
    required this.onAddPage,
    required this.titleController,
    required this.notesController,
    required this.selectedType,
    required this.issueDate,
    required this.issueDateError,
    required this.typeError,
    required this.titleError,
    required this.expiryDate,
    required this.onClearExpiryDate,
    required this.isSaving,
    required this.onTypeChanged,
    required this.onPickIssueDate,
    required this.onPickExpiryDate,
    required this.onConfirm,
  });

  final DocumentExtractionDraft? draft;
  final List<PickedFile> pickedFiles;
  final VoidCallback onAddPage;
  final TextEditingController titleController;
  final TextEditingController notesController;
  final PetDocumentType? selectedType;
  final DateTime? issueDate;
  final String? issueDateError;
  final String? typeError;
  final String? titleError;
  final DateTime? expiryDate;
  final VoidCallback onClearExpiryDate;
  final bool isSaving;
  final ValueChanged<PetDocumentType?> onTypeChanged;
  final VoidCallback onPickIssueDate;
  final VoidCallback onPickExpiryDate;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    final issueDateErrorColor =
        issueDateError == null ? null : Theme.of(context).colorScheme.error;

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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    pickedFiles.length == 1
                        ? '1 page attached'
                        : '${pickedFiles.length} pages attached',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddPage,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add page'),
                ),
              ],
            ),
            if (pickedFiles.isNotEmpty) ...[
              const SizedBox(height: 8),
              _AttachedPages(files: pickedFiles),
            ],
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
              decoration: InputDecoration(
                labelText: 'Type',
                errorText: typeError,
              ),
              items: [
                for (final type in PetDocumentType.values)
                  DropdownMenuItem(value: type, child: Text(_formatType(type))),
              ],
              onChanged: onTypeChanged,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                errorText: titleError,
              ),
            ),
            const SizedBox(height: 16),
            // The whole row turns red once saving has been attempted without
            // a date, rather than only its subtitle: the scan often cannot
            // read a date off the page, and this is the one field the owner
            // then has to fill in themselves.
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Issue date (required)',
                style: issueDateErrorColor == null
                    ? null
                    : TextStyle(color: issueDateErrorColor),
              ),
              subtitle: Text(
                issueDateError ??
                    (issueDate != null
                        ? dateFormat.format(issueDate!)
                        : 'Not set'),
                style: issueDateErrorColor == null
                    ? null
                    : TextStyle(color: issueDateErrorColor),
              ),
              trailing: Icon(
                Icons.calendar_today,
                color: issueDateErrorColor,
              ),
              onTap: onPickIssueDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiry date (optional)'),
              subtitle: Text(
                expiryDate != null ? dateFormat.format(expiryDate!) : 'Not set',
              ),
              // Clearable because the scan fills this in when the document
              // shows one, and a misread date has to be removable — the
              // field is optional, so there is no date to fall back to.
              trailing: expiryDate == null
                  ? const Icon(Icons.calendar_today)
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear expiry date',
                      onPressed: onClearExpiryDate,
                    ),
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
