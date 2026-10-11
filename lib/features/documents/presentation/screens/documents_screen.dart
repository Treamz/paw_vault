import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/app/router/app_router.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/presentation/widgets/adaptive_body.dart';
import 'package:paw_vault/core/presentation/widgets/adaptive_layout.dart';
import 'package:paw_vault/core/presentation/widgets/state_views.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/domain/services/document_file_opener.dart';
import 'package:paw_vault/features/documents/presentation/cubit/documents_cubit.dart';
import 'package:paw_vault/features/documents/presentation/widgets/attachment_views.dart';

@RoutePage()
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({
    @PathParam('petId') required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DocumentsCubit(
        documentRepository: context.read<DocumentRepository>(),
        authRepository: context.read<AuthRepository>(),
      )..load(petId),
      child: const _DocumentsView(),
    );
  }
}

enum _DocumentsSort { date, type }

class _DocumentsView extends StatefulWidget {
  const _DocumentsView();

  @override
  State<_DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<_DocumentsView> {
  _DocumentsSort _sort = _DocumentsSort.date;

  /// The cubit already delivers newest-first; "By type" groups by type name
  /// keeping newest-first within each group.
  List<PetDocument> _sorted(List<PetDocument> documents) {
    if (_sort == _DocumentsSort.date) {
      return documents;
    }
    final byType = [...documents]
      ..sort((a, b) => a.type.name.compareTo(b.type.name));
    return byType;
  }

  /// Warms the image cache for every attachment as soon as the list arrives.
  ///
  /// The previews live inside the details sheet, so without this the first tap
  /// on a document started the download and left the owner watching a blank
  /// box for a couple of seconds. `CachedNetworkImage` alone only fixes the
  /// *second* open.
  /// Held by id so that filtering, sorting or deleting cannot move the
  /// selection to whatever took that position.
  String? _selectedDocumentId;

  /// What the detail pane shows: the pick while it is still on screen, and
  /// otherwise the first, so the pane is never blank beside a full list.
  PetDocument? _shownDocument(List<PetDocument> visible) {
    if (visible.isEmpty) return null;
    final picked = _selectedDocumentId;
    for (final document in visible) {
      if (document.id.value == picked) return document;
    }
    return visible.first;
  }

  void _precacheAttachments(BuildContext context, DocumentsState state) {
    for (final document in state.documents) {
      for (final file in document.imageFiles) {
        precacheImage(
          CachedNetworkImageProvider(file.fileUrl.toString()),
          context,
          // Best effort: a warm-up failure must never surface to the owner.
          // The widget shows its own error state if the image is really gone.
          onError: (_, __) {},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final twoPanes = hasRoomForTwoPanes(MediaQuery.sizeOf(context));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          PopupMenuButton<_DocumentsSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort documents',
            initialValue: _sort,
            onSelected: (sort) => setState(() => _sort = sort),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _DocumentsSort.date,
                child: Text('Newest first'),
              ),
              PopupMenuItem(
                value: _DocumentsSort.type,
                child: Text('By type'),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<DocumentsCubit, DocumentsState>(
        listenWhen: (previous, current) =>
            previous.documents != current.documents,
        listener: _precacheAttachments,
        builder: (context, state) {
          final visible = state.status == DocumentsStatus.ready
              ? _sorted(state.filteredDocuments)
              : const <PetDocument>[];
          final shown = twoPanes ? _shownDocument(visible) : null;

          final list = switch (state.status) {
            DocumentsStatus.initial ||
            DocumentsStatus.loading =>
              const LoadingView(),
            DocumentsStatus.failure => ErrorStateView(
                title: 'Could not load documents',
                message: state.errorMessage,
              ),
            DocumentsStatus.ready => state.documents.isEmpty
                ? const EmptyStateView(
                    icon: Icons.folder_outlined,
                    title: 'No documents yet',
                    message: 'Upload passports, vaccination records, and '
                        'other documents to keep them in one place.',
                  )
                : Column(
                    children: [
                      _TypeFilterBar(
                        documents: state.documents,
                        selected: state.filterType,
                        onSelected: (type) {
                          final cubit = context.read<DocumentsCubit>();
                          if (type == null) {
                            cubit.clearFilters();
                          } else {
                            cubit.setTypeFilter(type);
                          }
                        },
                      ),
                      Expanded(
                        child: visible.isEmpty
                            ? const EmptyStateView(
                                icon: Icons.filter_alt_off_outlined,
                                title: 'No documents of this type',
                                message: 'Pick another type or All to see '
                                    'the rest of the documents.',
                              )
                            : _DocumentsContent(
                                documents: visible,
                                petId: state.petId!,
                                selectedDocumentId: shown?.id.value,
                                onSelect: twoPanes
                                    ? (document) => setState(
                                          () => _selectedDocumentId =
                                              document.id.value,
                                        )
                                    : null,
                              ),
                      ),
                    ],
                  ),
          };

          if (!twoPanes) return AdaptiveBody(child: list);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: twoPaneListWidth,
                child: Scaffold(
                  body: SafeArea(right: false, child: list),
                  floatingActionButton: _addDocumentButton(context, state),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: SafeArea(
                  left: false,
                  child: shown == null
                      ? const EmptyStateView(
                          icon: Icons.folder_outlined,
                          title: 'No document selected',
                          message: 'Pick a document to read it here.',
                        )
                      : DocumentDetailsView(
                          key: ValueKey(shown.id.value),
                          document: shown,
                          onEdit: () => context.router.push(
                            DocumentFormRoute(
                              petId: state.petId!,
                              documentId: shown.id.value,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: twoPanes
          ? null
          : BlocBuilder<DocumentsCubit, DocumentsState>(
              builder: _addDocumentButton,
            ),
    );
  }

  Widget _addDocumentButton(BuildContext context, DocumentsState state) {
    if (state.petId == null) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () =>
          context.router.push(DocumentFormRoute(petId: state.petId!)),
      icon: const Icon(Icons.add),
      label: const Text('Add document'),
    );
  }
}

/// Horizontal chips to show only one document type; only types the pet
/// actually has are offered.
class _TypeFilterBar extends StatelessWidget {
  const _TypeFilterBar({
    required this.documents,
    required this.selected,
    required this.onSelected,
  });

  final List<PetDocument> documents;
  final PetDocumentType? selected;
  final ValueChanged<PetDocumentType?> onSelected;

  @override
  Widget build(BuildContext context) {
    final types = PetDocumentType.values
        .where((type) => documents.any((document) => document.type == type))
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final type in types) ...[
            const SizedBox(width: 8),
            FilterChip(
              label: Text(_formatDocumentType(type)),
              selected: selected == type,
              onSelected: (isSelected) => onSelected(isSelected ? type : null),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentsContent extends StatelessWidget {
  const _DocumentsContent({
    required this.documents,
    required this.petId,
    this.selectedDocumentId,
    this.onSelect,
  });

  final List<PetDocument> documents;
  final String petId;

  /// Set only beside a detail pane, where a row picks what that pane shows
  /// instead of opening a sheet over everything.
  final String? selectedDocumentId;
  final void Function(PetDocument document)? onSelect;

  @override
  Widget build(BuildContext context) {
    final select = onSelect;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        select == null ? 16 : twoPaneListBottomInset,
      ),
      itemCount: documents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final document = documents[index];
        final expiry = document.expiryDate;
        return Card(
          child: ListTile(
            key: ValueKey('document-${document.id.value}'),
            // Standard type icons keep the list scannable; the attached
            // photo gets its own thumbnail on the trailing edge.
            leading: CircleAvatar(
              child: Icon(_documentIcon(document.type)),
            ),
            title: Text(document.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Documents saved before the issue date was required have
                  // none. Saying so beats omitting it silently: the row then
                  // explains why it sits at the end of the list.
                  document.issueDate != null
                      ? '${_formatDocumentType(document.type)} · '
                          '${DateFormat.yMMMd().format(document.issueDate!.toUtcDateTime())}'
                      : '${_formatDocumentType(document.type)} · No date',
                ),
                if (document.hasFile) ...[
                  const SizedBox(height: 4),
                  AttachmentLabel(count: document.files.length),
                ],
                if (expiry != null) ...[
                  const SizedBox(height: 4),
                  _ExpiryLabel(expiry: expiry),
                ],
              ],
            ),
            isThreeLine: expiry != null || document.hasFile,
            trailing: _DocumentThumbnail(document: document),
            selected: document.id.value == selectedDocumentId,
            onTap: () {
              if (select != null) {
                select(document);
                return;
              }
              _showDocumentDetails(context, document);
            },
          ),
        );
      },
    );
  }

  /// Read-only view first; editing is an explicit action from here.
  void _showDocumentDetails(BuildContext context, PetDocument document) {
    final router = context.router;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        builder: (context, scrollController) => DocumentDetailsView(
          document: document,
          scrollController: scrollController,
          onEdit: () {
            Navigator.of(sheetContext).pop();
            router.push(
              DocumentFormRoute(petId: petId, documentId: document.id.value),
            );
          },
        ),
      ),
    );
  }
}

/// A document, read-only.
///
/// Shown in a sheet on a phone and in the pane beside the list on a wide
/// surface. It takes how to edit rather than deciding, because only the
/// sheet has to close itself on the way.
class DocumentDetailsView extends StatelessWidget {
  const DocumentDetailsView({
    required this.document,
    required this.onEdit,
    this.scrollController,
    super.key,
  });

  final PetDocument document;
  final VoidCallback onEdit;

  /// Set by the sheet, which drives its own drag from this list.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileOpener = context.read<DocumentFileOpener>();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Row(
          children: [
            CircleAvatar(child: Icon(_documentIcon(document.type))),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                document.title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _detailRow(theme, 'Type', _formatDocumentType(document.type)),
        if (document.issueDate != null)
          _detailRow(
            theme,
            'Issued',
            DateFormat.yMMMMd().format(document.issueDate!.toUtcDateTime()),
          ),
        if (document.expiryDate != null)
          _detailRow(
            theme,
            'Expires',
            DateFormat.yMMMMd().format(document.expiryDate!.toUtcDateTime()),
          ),
        if (document.notes != null && document.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Notes', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(document.notes!),
        ],
        // Every attachment, not just the first: a scanned document can
        // have several pages, and showing one made the rest look lost.
        for (final file in document.files) ...[
          const SizedBox(height: 16),
          AttachmentPreview(attachment: file, fileOpener: fileOpener),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit document'),
        ),
      ],
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

IconData _documentIcon(PetDocumentType type) {
  return switch (type) {
    PetDocumentType.passport => Icons.menu_book,
    PetDocumentType.vaccinationCertificate => Icons.vaccines,
    PetDocumentType.insurance => Icons.shield,
    PetDocumentType.labResult => Icons.science,
    PetDocumentType.prescription => Icons.medication,
    PetDocumentType.receipt => Icons.receipt_long,
    PetDocumentType.vetReport => Icons.medical_information,
    PetDocumentType.other => Icons.description,
  };
}

String _formatDocumentType(PetDocumentType type) {
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

/// The row's trailing thumbnail, when the document has a photo to show.
class _DocumentThumbnail extends StatelessWidget {
  const _DocumentThumbnail({required this.document});

  final PetDocument document;

  @override
  Widget build(BuildContext context) {
    final thumbnail = document.imageFiles.firstOrNull;
    if (thumbnail == null) {
      return const SizedBox.shrink();
    }
    return AttachmentThumbnail(
      attachment: thumbnail,
      key: ValueKey('thumbnail-${thumbnail.storagePath}'),
    );
  }
}

class _ExpiryLabel extends StatelessWidget {
  const _ExpiryLabel({required this.expiry});

  final DateOnly expiry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateOnly.fromDateTime(DateTime.now());
    final isExpired = expiry.compareTo(today) < 0;
    final formatted = DateFormat.yMMMd().format(expiry.toUtcDateTime());

    return Row(
      children: [
        Icon(
          isExpired ? Icons.warning_amber : Icons.event,
          size: 16,
          color: isExpired ? theme.colorScheme.error : null,
        ),
        const SizedBox(width: 4),
        Text(
          isExpired ? 'Expired $formatted' : 'Expires $formatted',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isExpired ? theme.colorScheme.error : null,
            fontWeight: isExpired ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}
