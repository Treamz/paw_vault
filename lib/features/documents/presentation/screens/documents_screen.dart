import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/presentation/widgets/placeholder_feature_screen.dart';
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
      create: (context) =>
          DocumentsCubit(context.read<DocumentRepository>())..load(petId),
      child: PlaceholderFeatureScreen(
        title: 'Documents',
        description: 'Document archive placeholder for pet $petId.',
      ),
    );
  }
}
