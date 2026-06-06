import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/presentation/widgets/placeholder_feature_screen.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/presentation/cubit/pet_list_cubit.dart';

@RoutePage()
class PetListScreen extends StatelessWidget {
  const PetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PetListCubit(context.read<PetRepository>())..load(),
      child: const PlaceholderFeatureScreen(
        title: 'PawVault',
        description: 'Pet list placeholder for the local-first MVP.',
      ),
    );
  }
}
