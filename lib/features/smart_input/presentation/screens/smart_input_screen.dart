import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/presentation/widgets/placeholder_feature_screen.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';
import 'package:paw_vault/features/smart_input/presentation/cubit/smart_input_cubit.dart';

@RoutePage()
class SmartInputScreen extends StatelessWidget {
  const SmartInputScreen({
    @PathParam('petId') required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SmartInputCubit(context.read<SmartInputRepository>()),
      child: PlaceholderFeatureScreen(
        title: 'Smart Input',
        description:
            'AI-parsed draft placeholder for pet $petId. Drafts require review before saving.',
      ),
    );
  }
}
