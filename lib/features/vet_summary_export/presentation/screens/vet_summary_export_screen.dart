import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:paw_vault/core/presentation/widgets/placeholder_feature_screen.dart';

@RoutePage()
class VetSummaryExportScreen extends StatelessWidget {
  const VetSummaryExportScreen({
    @PathParam('petId') required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderFeatureScreen(
      title: 'Vet Summary',
      description: 'Export placeholder for pet $petId.',
    );
  }
}
