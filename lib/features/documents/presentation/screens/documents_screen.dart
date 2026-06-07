import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/app/router/app_router.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/presentation/cubit/documents_cubit.dart';

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

class _DocumentsView extends StatelessWidget {
  const _DocumentsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: SafeArea(
        child: BlocBuilder<DocumentsCubit, DocumentsState>(
          builder: (context, state) {
            return switch (state.status) {
              DocumentsStatus.initial ||
              DocumentsStatus.loading =>
                const _DocumentsLoading(),
              DocumentsStatus.failure => _DocumentsFailure(
                  message: state.errorMessage,
                ),
              DocumentsStatus.ready => state.documents.isEmpty
                  ? const _DocumentsEmpty()
                  : _DocumentsContent(
                      documents: state.documents,
                      petId: state.petId!,
                    ),
            };
          },
        ),
      ),
      floatingActionButton: BlocBuilder<DocumentsCubit, DocumentsState>(
        builder: (context, state) {
          if (state.petId == null) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () => context.router.push(
              DocumentFormRoute(petId: state.petId!),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add document'),
          );
        },
      ),
    );
  }
}

class _DocumentsLoading extends StatelessWidget {
  const _DocumentsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _DocumentsEmpty extends StatelessWidget {
  const _DocumentsEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No documents yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload passports, vaccination records, and other documents '
              'to keep them in one place.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentsFailure extends StatelessWidget {
  const _DocumentsFailure({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load documents',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DocumentsContent extends StatelessWidget {
  const _DocumentsContent({
    required this.documents,
    required this.petId,
  });

  final List<PetDocument> documents;
  final String petId;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final document = documents[index];
        final expiry = document.expiryDate;
        return Card(
          child: ListTile(
            key: ValueKey('document-${document.id.value}'),
            leading: CircleAvatar(
              child: Icon(_documentIcon(document.type)),
            ),
            title: Text(document.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDocumentType(document.type)),
                if (expiry != null) ...[
                  const SizedBox(height: 4),
                  _ExpiryLabel(expiry: expiry),
                ],
              ],
            ),
            isThreeLine: expiry != null,
            onTap: () => context.router.push(
              DocumentFormRoute(petId: petId, documentId: document.id.value),
            ),
          ),
        );
      },
    );
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
