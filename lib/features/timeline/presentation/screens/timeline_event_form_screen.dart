import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/timeline/presentation/cubit/timeline_event_cubit.dart';
import 'package:paw_vault/features/timeline/presentation/models/pet_event_form_state.dart';

@RoutePage()
class TimelineEventFormScreen extends StatelessWidget {
  const TimelineEventFormScreen({
    @PathParam('petId') required this.petId,
    @PathParam('eventId') this.eventId,
    super.key,
  });

  final String petId;
  final String? eventId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = TimelineEventCubit(
          timelineRepository: context.read<TimelineRepository>(),
          authRepository: context.read<AuthRepository>(),
        );
        if (eventId != null) {
          cubit.load(petId, eventId!);
        }
        return cubit;
      },
      child: _TimelineEventFormView(isEditMode: eventId != null),
    );
  }
}

class _TimelineEventFormView extends StatefulWidget {
  const _TimelineEventFormView({required this.isEditMode});

  final bool isEditMode;

  @override
  State<_TimelineEventFormView> createState() => _TimelineEventFormViewState();
}

class _TimelineEventFormViewState extends State<_TimelineEventFormView> {
  final _formKey = GlobalKey<FormState>();
  late PetEventFormState _formState;
  PetEventFormValidation? _validation;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _attachmentsController = TextEditingController();

  PetEventType? _selectedType;
  DateTime? _selectedDate;
  DateTime? _selectedReminderDate;

  @override
  void initState() {
    super.initState();
    _formState = const PetEventFormState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _attachmentsController.dispose();
    super.dispose();
  }

  void _loadEventData(PetEvent event) {
    setState(() {
      _formState = PetEventFormState.fromEvent(event);
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      _attachmentsController.text = event.attachments.map((uri) => uri.toString()).join(', ');
      _selectedType = event.type;
      _selectedDate = event.date.value;
      _selectedReminderDate = event.nextReminderDate?.value;
    });
  }

  void _updateFormState() {
    final attachments = _attachmentsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    setState(() {
      _formState = PetEventFormState(
        type: _selectedType,
        title: _titleController.text,
        date: _selectedDate,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        nextReminderDate: _selectedReminderDate,
        attachments: attachments,
      );
      _validation = _formState.validate();
    });
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _updateFormState();
      });
    }
  }

  Future<void> _selectReminderDate() async {
    final now = DateTime.now();
    final initialDate = _selectedReminderDate ?? _selectedDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _selectedDate ?? now,
      lastDate: DateTime(now.year + 2, now.month, now.day),
    );

    if (picked != null) {
      setState(() {
        _selectedReminderDate = picked;
        _updateFormState();
      });
    }
  }

  void _clearReminderDate() {
    setState(() {
      _selectedReminderDate = null;
      _updateFormState();
    });
  }

  void _saveEvent() {
    _updateFormState();

    if (_validation?.isValid != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors')),
      );
      return;
    }

    final cubit = context.read<TimelineEventCubit>();
    final screen = context.findAncestorWidgetOfExactType<TimelineEventFormScreen>();

    if (widget.isEditMode) {
      cubit.updateEvent(_formState);
    } else {
      cubit.createEvent(screen!.petId, _formState);
    }
  }

  String _formatEventType(PetEventType type) {
    final name = type.name;
    // Convert camelCase to Title Case with spaces
    final result = name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    return result.trim()[0].toUpperCase() + result.trim().substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();

    return BlocListener<TimelineEventCubit, TimelineEventState>(
      listener: (context, state) {
        if (state.status == TimelineEventStatus.ready && widget.isEditMode) {
          if (state.event != null && _titleController.text.isEmpty) {
            _loadEventData(state.event!);
          }
        }

        if (state.status == TimelineEventStatus.ready &&
            state.event != null &&
            !widget.isEditMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event saved successfully')),
          );
          context.router.back();
        }

        if (state.status == TimelineEventStatus.ready &&
            widget.isEditMode &&
            state.event == null) {
          // Event was deleted or form was successfully updated
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event updated successfully')),
          );
          context.router.back();
        }

        if (state.status == TimelineEventStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to save event'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditMode ? 'Edit Event' : 'Add Event'),
        ),
        body: BlocBuilder<TimelineEventCubit, TimelineEventState>(
          builder: (context, state) {
            if (widget.isEditMode && state.status == TimelineEventStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (widget.isEditMode && state.status == TimelineEventStatus.notFound) {
              return const Center(child: Text('Event not found'));
            }

            final isSaving = state.status == TimelineEventStatus.saving;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<PetEventType>(
                      initialValue: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'Event Type *',
                        errorText: _validation?.errorFor('type'),
                      ),
                      items: PetEventType.values
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(_formatEventType(type)),
                              ))
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _selectedType = value;
                                _updateFormState();
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title *',
                        errorText: _validation?.errorFor('title'),
                      ),
                      enabled: !isSaving,
                      onChanged: (_) => _updateFormState(),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Date *'),
                      subtitle: Text(_selectedDate != null
                          ? dateFormat.format(_selectedDate!)
                          : 'Not set'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: isSaving ? null : _selectDate,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_validation?.errorFor('date') != null) ...[
                      Text(
                        _validation!.errorFor('date')!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        errorText: _validation?.errorFor('description'),
                        hintText: 'Optional details about the event',
                      ),
                      maxLines: 4,
                      enabled: !isSaving,
                      onChanged: (_) => _updateFormState(),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Reminder Date'),
                      subtitle: Text(_selectedReminderDate != null
                          ? dateFormat.format(_selectedReminderDate!)
                          : 'Not set'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedReminderDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: isSaving ? null : _clearReminderDate,
                            ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                      onTap: isSaving ? null : _selectReminderDate,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_validation?.errorFor('nextReminderDate') != null) ...[
                      Text(
                        _validation!.errorFor('nextReminderDate')!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _attachmentsController,
                      decoration: InputDecoration(
                        labelText: 'Attachments',
                        hintText: 'Comma-separated URLs (e.g., https://...)',
                        errorText: _validation?.errorFor('attachments'),
                      ),
                      enabled: !isSaving,
                      onChanged: (_) => _updateFormState(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isSaving ? null : _saveEvent,
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.isEditMode ? 'Save Changes' : 'Add Event'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: isSaving ? null : () => context.router.back(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
