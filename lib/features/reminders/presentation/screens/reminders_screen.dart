import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/app/router/app_router.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/presentation/widgets/state_views.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/reminders/domain/services/reminder_notification_scheduler.dart';
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
        notificationScheduler: context.read<ReminderNotificationScheduler>(),
      )..load(petId),
      child: const _RemindersView(),
    );
  }
}

class _RemindersView extends StatelessWidget {
  const _RemindersView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: SafeArea(
        child: BlocBuilder<RemindersCubit, RemindersState>(
          builder: (context, state) {
            return switch (state.status) {
              RemindersStatus.initial ||
              RemindersStatus.loading =>
                const LoadingView(),
              RemindersStatus.failure => ErrorStateView(
                  title: 'Could not load reminders',
                  message: state.errorMessage,
                ),
              RemindersStatus.ready => state.reminders.isEmpty
                  ? const EmptyStateView(
                      icon: Icons.notifications_none,
                      title: 'No reminders yet',
                      message: 'Add reminders for vaccinations, medications, '
                          'and check-ups so nothing slips through.',
                    )
                  : _RemindersContent(
                      reminders: state.sortedReminders,
                      petId: state.petId!,
                    ),
            };
          },
        ),
      ),
      floatingActionButton: BlocBuilder<RemindersCubit, RemindersState>(
        builder: (context, state) {
          if (state.petId == null) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () => context.router.push(
              ReminderFormRoute(petId: state.petId!),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add reminder'),
          );
        },
      ),
    );
  }
}

class _RemindersContent extends StatelessWidget {
  const _RemindersContent({
    required this.reminders,
    required this.petId,
  });

  final List<Reminder> reminders;
  final String petId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMMd().add_jm();
    final now = DateTime.now();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reminders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        final due = reminder.dateTime.value.toLocal();
        final isOverdue = !reminder.isCompleted && due.isBefore(now);
        final repeat = _formatRepeat(reminder.repeatType);

        return Card(
          child: ListTile(
            key: ValueKey('reminder-${reminder.id.value}'),
            leading: Icon(
              reminder.isCompleted
                  ? Icons.check_circle
                  : isOverdue
                      ? Icons.warning_amber
                      : Icons.notifications_active,
              color: reminder.isCompleted
                  ? theme.disabledColor
                  : isOverdue
                      ? theme.colorScheme.error
                      : null,
            ),
            title: Text(
              reminder.title,
              style: reminder.isCompleted
                  ? TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: theme.disabledColor,
                    )
                  : null,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(due),
                  style: isOverdue
                      ? TextStyle(color: theme.colorScheme.error)
                      : null,
                ),
                if (repeat != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.repeat, size: 14),
                      const SizedBox(width: 4),
                      Text(repeat, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ],
            ),
            isThreeLine: repeat != null,
            trailing: Checkbox(
              value: reminder.isCompleted,
              onChanged: (_) =>
                  context.read<RemindersCubit>().toggleCompleted(reminder),
            ),
            onTap: () => context.router.push(
              ReminderFormRoute(petId: petId, reminderId: reminder.id.value),
            ),
          ),
        );
      },
    );
  }

  String? _formatRepeat(ReminderRepeatType? type) {
    return switch (type) {
      null || ReminderRepeatType.none => null,
      ReminderRepeatType.daily => 'Repeats daily',
      ReminderRepeatType.weekly => 'Repeats weekly',
      ReminderRepeatType.monthly => 'Repeats monthly',
      ReminderRepeatType.yearly => 'Repeats yearly',
      ReminderRepeatType.custom => 'Custom repeat',
    };
  }
}
