import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/presentation/widgets/placeholder_feature_screen.dart';
import 'package:paw_vault/features/vet_summary_export/domain/repositories/vet_summary_export_repository.dart';
import 'package:paw_vault/features/vet_summary_export/presentation/cubit/vet_summary_export_cubit.dart';

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
        context.read<VetSummaryExportRepository>(),
      )..load(petId),
      child: PlaceholderFeatureScreen(
        title: 'Vet Summary',
        description: 'Export placeholder for pet $petId.',
      ),
    );
  }
}
