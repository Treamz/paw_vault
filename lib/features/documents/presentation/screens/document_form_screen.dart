import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/documents/application/document_upload_service.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/domain/services/document_file_opener.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/documents/presentation/cubit/document_form_cubit.dart';
import 'package:paw_vault/features/documents/presentation/models/pet_document_form_state.dart';

@RoutePage()
class DocumentFormScreen extends StatelessWidget {
  const DocumentFormScreen({
    @PathParam('petId') required this.petId,
    @QueryParam('documentId') this.documentId,
    super.key,
  });

  final String petId;
  final String? documentId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = DocumentFormCubit(
          documentRepository: context.read<DocumentRepository>(),
          authRepository: context.read<AuthRepository>(),
          storageRepository: context.read<StorageRepository>(),
          uploadService: DocumentUploadService(
            filePicker: context.read<FilePicker>(),
            storageRepository: context.read<StorageRepository>(),
          ),
          analytics: context.read<AnalyticsService>(),
        );
        if (documentId != null) {
          cubit.load(petId, documentId!);
        }
        return cubit;
      },
      child: _DocumentFormView(
        petId: petId,
        isEditMode: documentId != null,
      ),
    );
  }
}

class _DocumentFormView extends StatefulWidget {
  const _DocumentFormView({
    required this.petId,
    required this.isEditMode,
  });

  final String petId;
  final bool isEditMode;

  @override
  State<_DocumentFormView> createState() => _DocumentFormViewState();
}

class _DocumentFormViewState extends State<_DocumentFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  PetDocumentType? _selectedType;
  DateTime? _issueDate;
  DateTime? _expiryDate;
  bool _populated = false;
  bool _submitted = false;
  bool _deleteRequested = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateFrom(PetDocument document) {
    setState(() {
      _populated = true;
      _titleController.text = document.title;
      _notesController.text = document.notes ?? '';
      _selectedType = document.type;
      _issueDate = document.issueDate?.toUtcDateTime();
      _expiryDate = document.expiryDate?.toUtcDateTime();
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

  Future<void> _pickIssueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
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
      initialDate: _expiryDate ?? _issueDate ?? now,
      firstDate: _issueDate ?? DateTime(now.year - 100),
      lastDate: DateTime(now.year + 100),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  void _submit(BuildContext context) {
    final formState = _buildFormState();
    final validation = formState.validate();
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors')),
      );
      setState(() {}); // surface field errors
      return;
    }

    setState(() => _submitted = true);
    final cubit = context.read<DocumentFormCubit>();
    if (widget.isEditMode) {
      cubit.updateDocument(formState);
    } else {
      cubit.createDocument(widget.petId, formState);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text(
          'Are you sure you want to delete this document? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      setState(() => _deleteRequested = true);
      context.read<DocumentFormCubit>().deleteDocument();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Document' : 'Add Document'),
        actions: [
          if (widget.isEditMode)
            BlocBuilder<DocumentFormCubit, DocumentFormState>(
              builder: (context, state) {
                final canDelete = state.status == DocumentFormStatus.ready &&
                    state.document != null;
                if (!canDelete) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete document',
                  onPressed: () => _confirmDelete(context),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<DocumentFormCubit, DocumentFormState>(
          listener: (context, state) {
            if (state.status == DocumentFormStatus.ready &&
                widget.isEditMode &&
                state.document != null &&
                !_populated) {
              _populateFrom(state.document!);
            }

            // A delete the user confirmed has completed (document removed).
            if (_deleteRequested &&
                state.status == DocumentFormStatus.ready &&
                state.document == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document deleted')),
              );
              context.router.maybePop();
              return;
            }

            // A save (create or edit) the user initiated has completed.
            if (_submitted && state.status == DocumentFormStatus.ready) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document saved')),
              );
              context.router.maybePop();
            }

            if (state.status == DocumentFormStatus.failure) {
              setState(() {
                _submitted = false;
                _deleteRequested = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Something went wrong'),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == DocumentFormStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == DocumentFormStatus.notFound) {
              return const Center(child: Text('Document not found'));
            }

            final isBusy = state.status == DocumentFormStatus.saving ||
                state.status == DocumentFormStatus.deleting;

            return AbsorbPointer(
              absorbing: isBusy,
              child: _form(context, isBusy, state.document),
            );
          },
        ),
      ),
    );
  }

  Widget _form(BuildContext context, bool isSaving, PetDocument? document) {
    final dateFormat = DateFormat.yMMMMd();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (document != null) ...[
              _AttachedFileCard(document: document),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<PetDocumentType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final type in PetDocumentType.values)
                  DropdownMenuItem(
                    value: type,
                    child: Text(_formatType(type)),
                  ),
              ],
              onChanged: (value) => setState(() => _selectedType = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _DateField(
              label: 'Issue date',
              value: _issueDate,
              format: dateFormat,
              onTap: _pickIssueDate,
              onClear: _issueDate == null
                  ? null
                  : () => setState(() => _issueDate = null),
            ),
            const SizedBox(height: 16),
            _DateField(
              label: 'Expiry date (optional)',
              value: _expiryDate,
              format: dateFormat,
              onTap: _pickExpiryDate,
              onClear: _expiryDate == null
                  ? null
                  : () => setState(() => _expiryDate = null),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                alignLabelWithHint: true,
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: isSaving ? null : () => _submit(context),
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(widget.isEditMode ? Icons.save : Icons.upload_file),
              label: Text(
                widget.isEditMode ? 'Save changes' : 'Pick file & save',
              ),
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

/// Shows the document's stored file (the original upload/scan): an inline
/// preview for images, a labeled tile for other files, and an action to open
/// the file externally.
class _AttachedFileCard extends StatelessWidget {
  const _AttachedFileCard({required this.document});

  final PetDocument document;

  Future<void> _open(BuildContext context) async {
    final opened =
        await context.read<DocumentFileOpener>().open(document.fileUrl);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the file')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final extension = document.fileExtension;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (document.hasImageFile)
            Image.network(
              document.fileUrl.toString(),
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) => Container(
                height: 180,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_outlined, size: 48),
              ),
            ),
          ListTile(
            leading: Icon(
              document.hasImageFile
                  ? Icons.image_outlined
                  : Icons.picture_as_pdf_outlined,
            ),
            title: const Text('Attached file'),
            subtitle: Text(
              extension.isEmpty ? 'File' : extension.toUpperCase(),
            ),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _open(context),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.format,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final DateFormat format;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: onClear != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear date',
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_today),
        ),
        child: Text(value != null ? format.format(value!) : 'Not set'),
      ),
    );
  }
}
