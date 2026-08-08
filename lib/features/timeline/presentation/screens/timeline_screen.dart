import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/app/router/app_router.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/presentation/widgets/full_screen_image.dart';
import 'package:paw_vault/core/presentation/widgets/state_views.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
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
      create: (context) => TimelineCubit(
        timelineRepository: context.read<TimelineRepository>(),
        authRepository: context.read<AuthRepository>(),
      )..load(petId),
      child: const _TimelineView(),
    );
  }
}

class _TimelineView extends StatelessWidget {
  const _TimelineView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: SafeArea(
        child: BlocBuilder<TimelineCubit, TimelineState>(
          builder: (context, state) {
            return switch (state.status) {
              TimelineStatus.initial ||
              TimelineStatus.loading =>
                const LoadingView(),
              TimelineStatus.failure => ErrorStateView(
                  title: 'Could not load timeline',
                  message: state.errorMessage,
                ),
              TimelineStatus.ready => state.filteredEvents.isEmpty
                  ? const EmptyStateView(
                      icon: Icons.timeline,
                      title: 'No events yet',
                      message: "Add health events to track your pet's "
                          'medical history.',
                    )
                  : _TimelineContent(
                      events: state.filteredEvents,
                      petId: state.petId!,
                    ),
            };
          },
        ),
      ),
      floatingActionButton: BlocBuilder<TimelineCubit, TimelineState>(
        builder: (context, state) {
          if (state.petId == null) return const SizedBox.shrink();

          return FloatingActionButton(
            tooltip: 'Add event',
            onPressed: () {
              context.router.push(
                TimelineEventFormRoute(petId: state.petId!),
              );
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

class _TimelineContent extends StatelessWidget {
  const _TimelineContent({
    required this.events,
    required this.petId,
  });

  final List<PetEvent> events;
  final String petId;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          child: ListTile(
            key: ValueKey('event-${event.id.value}'),
            leading: CircleAvatar(
              child: Icon(_eventIcon(event.type)),
            ),
            title: Text(event.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatEventType(event.type)),
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMMMd().format(event.date.value.toLocal()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (event.nextReminderDate != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reminder ${DateFormat.yMMMd().format(event.nextReminderDate!.value.toLocal())}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            isThreeLine: true,
            onTap: () => _showEventDetails(context, event),
          ),
        );
      },
    );
  }

  /// Full read-only details; editing is an explicit action from here.
  void _showEventDetails(BuildContext context, PetEvent event) {
    final router = context.router;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Row(
                children: [
                  CircleAvatar(child: Icon(_eventIcon(event.type))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event.title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow('Type', _formatEventType(event.type)),
              _DetailRow(
                'Date',
                DateFormat.yMMMMd().format(event.date.value.toLocal()),
              ),
              if (event.nextReminderDate != null)
                _DetailRow(
                  'Reminder',
                  DateFormat.yMMMMd()
                      .format(event.nextReminderDate!.value.toLocal()),
                ),
              if (event.description != null &&
                  event.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Description', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(event.description!),
              ],
              if (event.attachments.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Attachments', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final attachment in event.attachments)
                      GestureDetector(
                        onTap: () => showFullScreenImage(
                          context,
                          NetworkImage(attachment.toString()),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            attachment.toString(),
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) => Container(
                              width: 110,
                              height: 110,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.image_outlined),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  router.push(
                    TimelineEventFormRoute(
                      petId: petId,
                      eventId: event.id.value,
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit event'),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _eventIcon(PetEventType type) {
    return switch (type) {
      PetEventType.vaccination => Icons.vaccines,
      PetEventType.vetVisit => Icons.local_hospital,
      PetEventType.medication => Icons.medication,
      PetEventType.labTest => Icons.science,
      PetEventType.surgery => Icons.healing,
      PetEventType.symptom => Icons.sick,
      PetEventType.grooming => Icons.content_cut,
      PetEventType.food => Icons.restaurant,
      PetEventType.allergy => Icons.warning,
      PetEventType.documentAdded => Icons.insert_drive_file,
      PetEventType.other => Icons.event_note,
    };
  }

  String _formatEventType(PetEventType type) {
    return switch (type) {
      PetEventType.vaccination => 'Vaccination',
      PetEventType.vetVisit => 'Vet Visit',
      PetEventType.medication => 'Medication',
      PetEventType.labTest => 'Lab Test',
      PetEventType.surgery => 'Surgery',
      PetEventType.symptom => 'Symptom',
      PetEventType.grooming => 'Grooming',
      PetEventType.food => 'Food',
      PetEventType.allergy => 'Allergy',
      PetEventType.documentAdded => 'Document Added',
      PetEventType.other => 'Other',
    };
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
