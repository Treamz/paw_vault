import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/presentation/widgets/placeholder_feature_screen.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/reminders/presentation/cubit/reminders_cubit.dart';

@RoutePage()
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({
    @PathParam('petId') required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RemindersCubit(
        reminderRepository: context.read<ReminderRepository>(),
        authRepository: context.read<AuthRepository>(),
      )..load(petId),
      child: PlaceholderFeatureScreen(
        title: 'Reminders',
        description: 'Reminder placeholder for pet $petId.',
      ),
    );
  }
}
