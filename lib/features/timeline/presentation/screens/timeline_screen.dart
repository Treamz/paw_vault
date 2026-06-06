import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/presentation/widgets/placeholder_feature_screen.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/timeline/presentation/cubit/timeline_cubit.dart';

@RoutePage()
class TimelineScreen extends StatelessWidget {
  const TimelineScreen({
    @PathParam('petId') required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TimelineCubit(context.read<TimelineRepository>())..load(petId),
      child: PlaceholderFeatureScreen(
        title: 'Timeline',
        description: 'Health event timeline placeholder for pet $petId.',
      ),
    );
  }
}
