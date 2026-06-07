import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
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
                const _TimelineLoading(),
              TimelineStatus.failure => _TimelineFailure(
                  message: state.errorMessage,
                ),
              TimelineStatus.ready => state.filteredEvents.isEmpty
                  ? const _TimelineEmpty()
                  : _TimelineContent(events: state.filteredEvents),
            };
          },
        ),
      ),
    );
  }
}

class _TimelineLoading extends StatelessWidget {
  const _TimelineLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _TimelineEmpty extends StatelessWidget {
  const _TimelineEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timeline,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No events yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add health events to track your pet\'s medical history.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineFailure extends StatelessWidget {
  const _TimelineFailure({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load timeline',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineContent extends StatelessWidget {
  const _TimelineContent({required this.events});

  final List<PetEvent> events;

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
                  DateFormat.yMMMd().format(event.date.value),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            isThreeLine: true,
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
