import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
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
                  : _DocumentsContent(documents: state.documents),
            };
          },
        ),
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
  const _DocumentsContent({required this.documents});

  final List<PetDocument> documents;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final document = documents[index];
        return Card(
          child: ListTile(
            key: ValueKey('document-${document.id.value}'),
            leading: const CircleAvatar(
              child: Icon(Icons.description),
            ),
            title: Text(document.title),
            subtitle: Text(_formatDocumentType(document.type)),
          ),
        );
      },
    );
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
