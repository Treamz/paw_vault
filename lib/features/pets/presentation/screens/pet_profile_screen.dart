import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/presentation/widgets/placeholder_feature_screen.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/presentation/cubit/pet_profile_cubit.dart';

@RoutePage()
class PetProfileScreen extends StatelessWidget {
  const PetProfileScreen({
    @PathParam('petId') required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PetProfileCubit(context.read<PetRepository>())..load(petId),
      child: PlaceholderFeatureScreen(
        title: 'Pet Profile',
        description: 'Profile placeholder for pet $petId.',
      ),
    );
  }
}
