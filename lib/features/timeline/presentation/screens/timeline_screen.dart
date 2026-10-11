import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/app/router/app_router.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/presentation/widgets/adaptive_body.dart';
import 'package:paw_vault/core/presentation/widgets/adaptive_layout.dart';
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

class _TimelineView extends StatefulWidget {
  const _TimelineView();

  @override
  State<_TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<_TimelineView> {
  /// Held by id so that an event arriving or leaving cannot move the
  /// selection to whatever took that position.
  String? _selectedEventId;

  /// What the detail pane shows: the pick while it is still on screen, and
  /// otherwise the first, so the pane is never blank beside a full list.
  PetEvent? _shownEvent(List<PetEvent> visible) {
    if (visible.isEmpty) return null;
    final picked = _selectedEventId;
    for (final event in visible) {
      if (event.id.value == picked) return event;
    }
    return visible.first;
  }

  @override
  Widget build(BuildContext context) {
    final twoPanes = hasRoomForTwoPanes(MediaQuery.sizeOf(context));

    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: BlocBuilder<TimelineCubit, TimelineState>(
        builder: (context, state) {
          final visible = state.status == TimelineStatus.ready
              ? state.filteredEvents
              : const <PetEvent>[];
          final shown = twoPanes ? _shownEvent(visible) : null;

          final list = switch (state.status) {
            TimelineStatus.initial ||
            TimelineStatus.loading =>
              const LoadingView(),
            TimelineStatus.failure => ErrorStateView(
                title: 'Could not load timeline',
                message: state.errorMessage,
              ),
            TimelineStatus.ready => visible.isEmpty
                ? const EmptyStateView(
                    icon: Icons.timeline,
                    title: 'No events yet',
                    message: "Add health events to track your pet's "
                        'medical history.',
                  )
                : _TimelineContent(
                    events: visible,
                    petId: state.petId!,
                    selectedEventId: shown?.id.value,
                    onSelect: twoPanes
                        ? (event) => setState(
                              () => _selectedEventId = event.id.value,
                            )
                        : null,
                  ),
          };

          if (!twoPanes) return AdaptiveBody(child: list);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: twoPaneListWidth,
                child: Scaffold(
                  body: SafeArea(right: false, child: list),
                  floatingActionButton: _addEventButton(context, state),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: SafeArea(
                  left: false,
                  child: shown == null
                      ? const EmptyStateView(
                          icon: Icons.timeline,
                          title: 'No event selected',
                          message: 'Pick an event to read it here.',
                        )
                      : EventDetailsView(
                          key: ValueKey(shown.id.value),
                          event: shown,
                          onEdit: () => context.router.push(
                            TimelineEventFormRoute(
                              petId: state.petId!,
                              eventId: shown.id.value,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: twoPanes
          ? null
          : BlocBuilder<TimelineCubit, TimelineState>(
              builder: _addEventButton,
            ),
    );
  }

  Widget _addEventButton(BuildContext context, TimelineState state) {
    if (state.petId == null) return const SizedBox.shrink();

    return FloatingActionButton(
      tooltip: 'Add event',
      onPressed: () => context.router.push(
        TimelineEventFormRoute(petId: state.petId!),
      ),
      child: const Icon(Icons.add),
    );
  }
}

class _TimelineContent extends StatelessWidget {
  const _TimelineContent({
    required this.events,
    required this.petId,
    this.selectedEventId,
    this.onSelect,
  });

  final List<PetEvent> events;
  final String petId;

  /// Set only beside a detail pane, where a row picks what that pane shows
  /// instead of opening a sheet over everything.
  final String? selectedEventId;
  final void Function(PetEvent event)? onSelect;

  @override
  Widget build(BuildContext context) {
    final select = onSelect;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        select == null ? 16 : twoPaneListBottomInset,
      ),
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
                        // With the time: a reminder for a specific moment
                        // reads as a guess without it.
                        'Reminder '
                        '${DateFormat.yMMMd().add_jm().format(event.nextReminderDate!.value.toLocal())}',
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
            selected: event.id.value == selectedEventId,
            onTap: () {
              if (select != null) {
                select(event);
                return;
              }
              _showEventDetails(context, event);
            },
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
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) => EventDetailsView(
          event: event,
          scrollController: scrollController,
          onEdit: () {
            Navigator.of(sheetContext).pop();
            router.push(
              TimelineEventFormRoute(petId: petId, eventId: event.id.value),
            );
          },
        ),
      ),
    );
  }
}

/// An event, read-only.
///
/// Shown in a sheet on a phone and in the pane beside the list on a wide
/// surface. It takes how to edit rather than deciding, because only the
/// sheet has to close itself on the way.
class EventDetailsView extends StatelessWidget {
  const EventDetailsView({
    required this.event,
    required this.onEdit,
    this.scrollController,
    super.key,
  });

  final PetEvent event;
  final VoidCallback onEdit;

  /// Set by the sheet, which drives its own drag from this list.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
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
                .add_jm()
                .format(event.nextReminderDate!.value.toLocal()),
          ),
        if (event.description != null && event.description!.isNotEmpty) ...[
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
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit event'),
        ),
      ],
    );
  }
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
