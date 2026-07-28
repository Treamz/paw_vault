import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/timeline/application/event_attachment_upload_service.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/timeline/domain/services/event_photo_picker.dart';
import 'package:paw_vault/features/timeline/presentation/cubit/timeline_event_cubit.dart';
import 'package:paw_vault/features/timeline/presentation/models/pet_event_form_state.dart';

@RoutePage()
class TimelineEventFormScreen extends StatelessWidget {
  const TimelineEventFormScreen({
    @PathParam('petId') required this.petId,
    @QueryParam('eventId') this.eventId,
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
          attachmentUploadService: EventAttachmentUploadService(
            storageRepository: context.read<StorageRepository>(),
          ),
          analytics: context.read<AnalyticsService>(),
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

  PetEventType? _selectedType;
  DateTime? _selectedDate;
  DateTime? _selectedReminderDate;
  List<String> _attachmentUrls = [];
  final List<PickedEventPhoto> _pendingPhotos = [];

  Future<void> _pickAttachmentPhoto(EventPhotoSource source) async {
    final picker = context.read<EventPhotoPicker>();
    try {
      final photo = await picker.pick(source);
      if (photo == null || !mounted) {
        return;
      }
      setState(() {
        _pendingPhotos.add(photo);
        _updateFormState();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick a photo')),
      );
    }
  }

  void _removeStoredAttachment(int index) {
    setState(() {
      _attachmentUrls = List.of(_attachmentUrls)..removeAt(index);
      _updateFormState();
    });
  }

  void _removePendingPhoto(int index) {
    setState(() {
      _pendingPhotos.removeAt(index);
      _updateFormState();
    });
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
          'Are you sure you want to delete this event? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<TimelineEventCubit>().deleteEvent();
    }
  }

  @override
  void initState() {
    super.initState();
    _formState = const PetEventFormState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadEventData(PetEvent event) {
    setState(() {
      _formState = PetEventFormState.fromEvent(event);
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      _attachmentUrls = event.attachments.map((uri) => uri.toString()).toList();
      _pendingPhotos.clear();
      _selectedType = event.type;
      _selectedDate = event.date.value.toLocal();
      _selectedReminderDate = event.nextReminderDate?.value.toLocal();
    });
  }

  void _updateFormState() {
    setState(() {
      _formState = PetEventFormState(
        type: _selectedType,
        title: _titleController.text,
        date: _selectedDate,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        nextReminderDate: _selectedReminderDate,
        attachments: List.of(_attachmentUrls),
        pendingPhotos: List.of(_pendingPhotos),
      );
      // Field errors only appear after a save attempt; typing before that
      // must not paint untouched fields red.
      if (_validation != null) {
        _validation = _formState.validate();
      }
    });
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
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
    // A reminder may be earlier than the event itself (e.g. a heads-up a few
    // days before an appointment), so it is not constrained to the event date.
    final firstDate = DateTime(now.year - 100, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
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
    final validation = _formState.validate();

    if (!validation.isValid) {
      setState(() => _validation = validation);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors')),
      );
      return;
    }

    final cubit = context.read<TimelineEventCubit>();
    final screen =
        context.findAncestorWidgetOfExactType<TimelineEventFormScreen>();

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
          } else if (state.event == null) {
            // Event was deleted successfully
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event deleted successfully')),
            );
            context.router.back();
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
          actions: [
            if (widget.isEditMode)
              BlocBuilder<TimelineEventCubit, TimelineEventState>(
                builder: (context, state) {
                  if (state.status == TimelineEventStatus.ready &&
                      state.event != null) {
                    return IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: state.status == TimelineEventStatus.deleting
                          ? null
                          : () => _showDeleteConfirmation(context),
                      tooltip: 'Delete event',
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
        body: BlocBuilder<TimelineEventCubit, TimelineEventState>(
          builder: (context, state) {
            if (widget.isEditMode &&
                state.status == TimelineEventStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (widget.isEditMode &&
                state.status == TimelineEventStatus.notFound) {
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
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(_formatEventType(type)),
                            ),
                          )
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
                      subtitle: Text(
                        _selectedDate != null
                            ? dateFormat.format(_selectedDate!)
                            : 'Not set',
                      ),
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
                      subtitle: Text(
                        _selectedReminderDate != null
                            ? dateFormat.format(_selectedReminderDate!)
                            : 'Not set',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedReminderDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Clear reminder date',
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
                    const SizedBox(height: 24),
                    Text(
                      'Attachments',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (_attachmentUrls.isNotEmpty ||
                        _pendingPhotos.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < _attachmentUrls.length; i++)
                            _AttachmentThumbnail(
                              key: ValueKey('stored-$i'),
                              image: Image.network(
                                _attachmentUrls[i],
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (context, _, __) => Container(
                                  width: 72,
                                  height: 72,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  child: const Icon(Icons.image_outlined),
                                ),
                              ),
                              onRemove: isSaving
                                  ? null
                                  : () => _removeStoredAttachment(i),
                            ),
                          for (var i = 0; i < _pendingPhotos.length; i++)
                            _AttachmentThumbnail(
                              key: ValueKey('pending-$i'),
                              image: _pendingPhotos[i].extension == 'pdf'
                                  ? Container(
                                      width: 72,
                                      height: 72,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: const Icon(
                                        Icons.picture_as_pdf_outlined,
                                      ),
                                    )
                                  : Image.memory(
                                      _pendingPhotos[i].bytes,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    ),
                              onRemove: isSaving
                                  ? null
                                  : () => _removePendingPhoto(i),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () =>
                                  _pickAttachmentPhoto(EventPhotoSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Camera'),
                        ),
                        OutlinedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () => _pickAttachmentPhoto(
                                    EventPhotoSource.gallery,
                                  ),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                        ),
                        OutlinedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () => _pickAttachmentPhoto(
                                    EventPhotoSource.file,
                                  ),
                          icon: const Icon(Icons.attach_file),
                          label: const Text('File'),
                        ),
                      ],
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
                          : Text(
                              widget.isEditMode ? 'Save Changes' : 'Add Event',
                            ),
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

class _AttachmentThumbnail extends StatelessWidget {
  const _AttachmentThumbnail({
    required this.image,
    required this.onRemove,
    super.key,
  });

  final Widget image;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: image,
        ),
        Positioned(
          top: -8,
          right: -8,
          child: IconButton(
            icon: const Icon(Icons.cancel, size: 20),
            tooltip: 'Remove attachment',
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}
