import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/reminders/domain/services/reminder_notification_scheduler.dart';
import 'package:paw_vault/features/reminders/presentation/cubit/reminder_form_cubit.dart';
import 'package:paw_vault/features/reminders/presentation/models/reminder_form_state.dart';

@RoutePage()
class ReminderFormScreen extends StatelessWidget {
  const ReminderFormScreen({
    @PathParam('petId') required this.petId,
    @QueryParam('reminderId') this.reminderId,
    super.key,
  });

  final String petId;
  final String? reminderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = ReminderFormCubit(
          reminderRepository: context.read<ReminderRepository>(),
          authRepository: context.read<AuthRepository>(),
          notificationScheduler: context.read<ReminderNotificationScheduler>(),
        );
        if (reminderId != null) {
          cubit.load(petId, reminderId!);
        }
        return cubit;
      },
      child: _ReminderFormView(
        petId: petId,
        isEditMode: reminderId != null,
      ),
    );
  }
}

class _ReminderFormView extends StatefulWidget {
  const _ReminderFormView({required this.petId, required this.isEditMode});

  final String petId;
  final bool isEditMode;

  @override
  State<_ReminderFormView> createState() => _ReminderFormViewState();
}

class _ReminderFormViewState extends State<_ReminderFormView> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _dateTime;
  ReminderRepeatType _repeatType = ReminderRepeatType.none;
  bool _populated = false;
  bool _submitted = false;
  bool _deleteRequested = false;
  bool _completeRequested = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _populateFrom(Reminder reminder) {
    setState(() {
      _populated = true;
      _titleController.text = reminder.title;
      _descriptionController.text = reminder.description ?? '';
      _dateTime = reminder.dateTime.value;
      _repeatType = reminder.repeatType ?? ReminderRepeatType.none;
    });
  }

  ReminderFormState _buildFormState() {
    return ReminderFormState(
      title: _titleController.text,
      dateTime: _dateTime,
      repeatType: _repeatType,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime ?? now),
    );
    if (time == null) return;

    setState(() {
      _dateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit(BuildContext context) {
    final formState = _buildFormState();
    if (!formState.validate().isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors')),
      );
      return;
    }

    setState(() => _submitted = true);
    final cubit = context.read<ReminderFormCubit>();
    if (widget.isEditMode) {
      cubit.updateReminder(formState);
    } else {
      cubit.createReminder(widget.petId, formState);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text(
          'Are you sure you want to delete this reminder? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      setState(() => _deleteRequested = true);
      context.read<ReminderFormCubit>().deleteReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Reminder' : 'Add Reminder'),
        actions: [
          if (widget.isEditMode)
            BlocBuilder<ReminderFormCubit, ReminderFormCubitState>(
              builder: (context, state) {
                final reminder = state.reminder;
                if (state.status != ReminderFormStatus.ready ||
                    reminder == null) {
                  return const SizedBox.shrink();
                }
                return Row(
                  children: [
                    if (!reminder.isCompleted)
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        tooltip: 'Mark complete',
                        onPressed: () {
                          setState(() => _completeRequested = true);
                          context.read<ReminderFormCubit>().completeReminder();
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete reminder',
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<ReminderFormCubit, ReminderFormCubitState>(
          listener: (context, state) {
            if (state.status == ReminderFormStatus.ready &&
                widget.isEditMode &&
                state.reminder != null &&
                !_populated) {
              _populateFrom(state.reminder!);
            }

            // A delete the user confirmed has completed.
            if (_deleteRequested &&
                state.status == ReminderFormStatus.ready &&
                state.reminder == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reminder deleted')),
              );
              context.router.maybePop();
              return;
            }

            // A "mark complete" the user requested has completed.
            if (_completeRequested &&
                state.status == ReminderFormStatus.ready &&
                state.reminder?.isCompleted == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reminder marked complete')),
              );
              context.router.maybePop();
              return;
            }

            if (_submitted && state.status == ReminderFormStatus.ready) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reminder saved')),
              );
              context.router.maybePop();
            }

            if (state.status == ReminderFormStatus.failure) {
              setState(() {
                _submitted = false;
                _deleteRequested = false;
                _completeRequested = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Something went wrong'),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == ReminderFormStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == ReminderFormStatus.notFound) {
              return const Center(child: Text('Reminder not found'));
            }

            final isSaving = state.status == ReminderFormStatus.saving;
            final isBusy =
                isSaving || state.status == ReminderFormStatus.deleting;
            final dateFormat = DateFormat.yMMMMd().add_jm();

            return AbsorbPointer(
              absorbing: isBusy,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date & time'),
                      subtitle: Text(
                        _dateTime != null
                            ? dateFormat.format(_dateTime!)
                            : 'Not set',
                      ),
                      trailing: const Icon(Icons.event),
                      onTap: _pickDateTime,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ReminderRepeatType>(
                      initialValue: _repeatType,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Repeat'),
                      items: [
                        for (final type in ReminderRepeatType.values)
                          DropdownMenuItem(
                            value: type,
                            child: Text(_formatRepeat(type)),
                          ),
                      ],
                      onChanged: (value) => setState(
                        () => _repeatType = value ?? ReminderRepeatType.none,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: isSaving ? null : () => _submit(context),
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(isSaving ? 'Saving…' : 'Save reminder'),
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

  String _formatRepeat(ReminderRepeatType type) {
    return switch (type) {
      ReminderRepeatType.none => 'Does not repeat',
      ReminderRepeatType.daily => 'Daily',
      ReminderRepeatType.weekly => 'Weekly',
      ReminderRepeatType.monthly => 'Monthly',
      ReminderRepeatType.yearly => 'Yearly',
      ReminderRepeatType.custom => 'Custom',
    };
  }
}
