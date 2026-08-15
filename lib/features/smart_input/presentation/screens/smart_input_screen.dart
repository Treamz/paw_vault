import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/app/router/app_router.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';
import 'package:paw_vault/features/smart_input/presentation/cubit/smart_input_cubit.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';

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
      create: (context) => SmartInputCubit(
        smartInputRepository: context.read<SmartInputRepository>(),
        authRepository: context.read<AuthRepository>(),
        analytics: context.read<AnalyticsService>(),
      )..load(petId),
      child: _SmartInputView(petId: petId),
    );
  }
}

class _SmartInputView extends StatefulWidget {
  const _SmartInputView({required this.petId});

  final String petId;

  @override
  State<_SmartInputView> createState() => _SmartInputViewState();
}

class _SmartInputViewState extends State<_SmartInputView>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late final TabController _tabs = TabController(length: 2, vsync: this);

  /// The extracted details as the user edited them during review; null until
  /// the user changes something.
  Map<String, Object?>? _editedDraftData;

  @override
  void dispose() {
    _controller.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Input'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Analyze'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<SmartInputCubit, SmartInputState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == SmartInputStatus.confirmed) {
              _controller.clear();
              _editedDraftData = null;
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                SnackBar(
                  content: const Text('Analysis saved to History'),
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'View',
                    onPressed: () {
                      messenger.hideCurrentSnackBar();
                      _tabs.animateTo(1);
                    },
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            return TabBarView(
              controller: _tabs,
              children: [
                _buildAnalyzeTab(context, state),
                _HistoryTab(
                  state: state,
                  onAction: (message, type) =>
                      _handleHistoryAction(context, message, type),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleSuggestedAction(
    BuildContext context,
    SmartSuggestedActionType type,
  ) async {
    switch (type) {
      case SmartSuggestedActionType.createTimelineEvent:
        // Open the Add Event form pre-filled from the draft; the user
        // creates the event themselves — nothing is saved until they do.
        final draft = context.read<SmartInputCubit>().state.draft;
        if (draft == null) return;
        await context.router.push(
          _prefilledEventRoute(
            intent: draft.detectedIntent,
            originalText: draft.originalText,
            details: _editedDraftData ?? draft.extractedData,
          ),
        );
      case SmartSuggestedActionType.createReminder:
        await context.router.push(ReminderFormRoute(petId: widget.petId));
      default:
        break;
    }
  }

  /// Executes a suggested action from a saved history analysis.
  Future<void> _handleHistoryAction(
    BuildContext context,
    SmartMessage message,
    SmartSuggestedActionType type,
  ) async {
    switch (type) {
      case SmartSuggestedActionType.createTimelineEvent:
        await context.router.push(
          _prefilledEventRoute(
            intent: message.detectedIntent,
            originalText: message.originalText,
            details: message.extractedData,
          ),
        );
      case SmartSuggestedActionType.createReminder:
        await context.router.push(ReminderFormRoute(petId: widget.petId));
      default:
        break;
    }
  }

  /// Builds an Add Event route seeded from an analysis, mapping the detected
  /// intent to an event type and folding the details into the description.
  TimelineEventFormRoute _prefilledEventRoute({
    required SmartMessageIntent intent,
    required String originalText,
    required Map<String, Object?> details,
  }) {
    final text = originalText.trim();
    return TimelineEventFormRoute(
      petId: widget.petId,
      initialType: _eventTypeForIntent(intent),
      initialTitle: text.length <= 60 ? text : '${text.substring(0, 60)}…',
      initialDescription: [
        originalText,
        for (final entry in details.entries) '${entry.key}: ${entry.value}',
      ].join('\n'),
    );
  }

  static PetEventType _eventTypeForIntent(SmartMessageIntent intent) {
    return switch (intent) {
      SmartMessageIntent.addVaccination => PetEventType.vaccination,
      SmartMessageIntent.addMedication => PetEventType.medication,
      SmartMessageIntent.addSymptom => PetEventType.symptom,
      SmartMessageIntent.addVetVisit => PetEventType.vetVisit,
      SmartMessageIntent.addAllergy => PetEventType.allergy,
      SmartMessageIntent.addReminder ||
      SmartMessageIntent.addNote ||
      SmartMessageIntent.unknown =>
        PetEventType.other,
    };
  }

  Widget _buildAnalyzeTab(BuildContext context, SmartInputState state) {
    final isProcessing = state.isProcessing;
    final isSaving = state.isSaving;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AiDisclaimer(),
          const SizedBox(height: 16),
          // The draft goes on top so the user immediately sees the result
          // and that nothing is saved without confirmation.
          if (state.status == SmartInputStatus.failure &&
              state.errorMessage != null) ...[
            _ErrorBanner(message: state.errorMessage!),
            const SizedBox(height: 16),
          ],
          if (state.hasDraft) ...[
            _DraftReview(
              draft: state.draft!,
              onDataChanged: (data) => _editedDraftData = data,
              onAction: (type) => _handleSuggestedAction(context, type),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () {
                            _editedDraftData = null;
                            context.read<SmartInputCubit>().dismissDraft();
                          },
                    icon: const Icon(Icons.close),
                    label: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isSaving
                        ? null
                        : () => context.read<SmartInputCubit>().confirmDraft(
                              widget.petId,
                              extractedData: _editedDraftData,
                            ),
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(isSaving ? 'Saving…' : 'Confirm'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _controller,
            enabled: !isProcessing && !isSaving,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Describe what happened',
              hintText: 'e.g. Bella got her rabies shot today',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: isProcessing || isSaving
                ? null
                : () => context.read<SmartInputCubit>().submit(
                      _controller.text,
                    ),
            icon: isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(isProcessing ? 'Analyzing…' : 'Analyze'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isProcessing || isSaving
                ? null
                : () => context.router.push(
                      DocumentExtractionRoute(petId: widget.petId),
                    ),
            icon: const Icon(Icons.document_scanner),
            label: const Text('Attach document or photo'),
          ),
        ],
      ),
    );
  }
}

class _AiDisclaimer extends StatelessWidget {
  const _AiDisclaimer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI-assisted organizing',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This tool only structures what you write into a draft for '
                    'you to review, correct, and confirm — it never saves '
                    'anything on its own. It does not provide medical advice '
                    'and is not a substitute for your veterinarian.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Review card for the AI draft. Extracted details are editable and new ones
/// can be added, so the user controls exactly what gets saved.
class _DraftReview extends StatefulWidget {
  const _DraftReview({
    required this.draft,
    required this.onDataChanged,
    required this.onAction,
  });

  final SmartInputDraft draft;
  final ValueChanged<Map<String, Object?>> onDataChanged;
  final ValueChanged<SmartSuggestedActionType> onAction;

  @override
  State<_DraftReview> createState() => _DraftReviewState();
}

class _DraftReviewState extends State<_DraftReview> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(_DraftReview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.draft, widget.draft)) {
      _initControllers();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    for (final entry in widget.draft.extractedData.entries) {
      _controllers[entry.key] =
          TextEditingController(text: '${entry.value ?? ''}');
    }
  }

  void _notify() {
    widget.onDataChanged({
      for (final entry in _controllers.entries)
        if (entry.value.text.trim().isNotEmpty)
          entry.key: entry.value.text.trim(),
    });
  }

  String get _suggestedDetailName {
    return switch (widget.draft.detectedIntent) {
      SmartMessageIntent.addSymptom => 'symptom',
      SmartMessageIntent.addMedication => 'medication',
      SmartMessageIntent.addAllergy => 'allergen',
      SmartMessageIntent.addVaccination => 'vaccine',
      _ => 'detail',
    };
  }

  Future<void> _addDetail() async {
    final result = await showDialog<({String name, String value})>(
      context: context,
      builder: (_) => _AddDetailDialog(suggestedName: _suggestedDetailName),
    );
    if (result == null || result.value.trim().isEmpty) {
      return;
    }
    final baseName =
        result.name.trim().isEmpty ? _suggestedDetailName : result.name.trim();
    var name = baseName;
    var counter = 2;
    while (_controllers.containsKey(name)) {
      name = '$baseName $counter';
      counter++;
    }
    setState(() {
      _controllers[name] = TextEditingController(text: result.value.trim());
    });
    _notify();
  }

  void _removeDetail(String key) {
    setState(() => _controllers.remove(key)?.dispose());
    _notify();
  }

  bool get _isLowConfidence =>
      widget.draft.status == SmartInputDraftStatus.lowConfidenceReview ||
      (widget.draft.confidence != null && widget.draft.confidence! < 0.6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = widget.draft;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI draft',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (draft.confidence != null)
                  Chip(
                    label: Text(
                      '${(draft.confidence! * 100).round()}% confident',
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Nothing is saved until you confirm. Correct or add details '
              'below.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text('Detected intent', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(formatSmartIntent(draft.detectedIntent)),
            const SizedBox(height: 12),
            Text('Details', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            for (final key in _controllers.keys.toList())
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _controllers[key],
                        decoration: InputDecoration(
                          labelText: key,
                          isDense: true,
                        ),
                        onChanged: (_) => _notify(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      tooltip: 'Remove detail',
                      onPressed: () => _removeDetail(key),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addDetail,
                icon: const Icon(Icons.add),
                label: const Text('Add detail'),
              ),
            ),
            if (draft.suggestedActions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Suggested actions', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final action in draft.suggestedActions)
                    if (_isActionableType(action.type))
                      ActionChip(
                        avatar: Icon(_actionTypeIcon(action.type), size: 18),
                        label: Text(formatSmartAction(action.type)),
                        onPressed: () => widget.onAction(action.type),
                      )
                    else
                      Chip(
                        label: Text(formatSmartAction(action.type)),
                        visualDensity: VisualDensity.compact,
                      ),
                ],
              ),
            ],
            if (_isLowConfidence) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Low confidence — double-check before saving.',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Owns its controllers so they outlive the dialog's exit animation.
class _AddDetailDialog extends StatefulWidget {
  const _AddDetailDialog({required this.suggestedName});

  final String suggestedName;

  @override
  State<_AddDetailDialog> createState() => _AddDetailDialogState();
}

class _AddDetailDialogState extends State<_AddDetailDialog> {
  late final _nameController = TextEditingController(
    text: widget.suggestedName,
  );
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Detail'),
      content: TextField(
        controller: _valueController,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: widget.suggestedName,
          hintText: 'e.g. sneezing since yesterday',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            (name: _nameController.text, value: _valueController.text),
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// The dedicated History tab: every confirmed analysis with its full details.
class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.state, required this.onAction});

  final SmartInputState state;
  final void Function(SmartMessage message, SmartSuggestedActionType type)
      onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return switch (state.historyStatus) {
      SmartHistoryStatus.loading =>
        const Center(child: CircularProgressIndicator()),
      SmartHistoryStatus.failure => Center(
          child: Text(
            state.historyError ?? 'Could not load saved analyses',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      SmartHistoryStatus.ready => state.messages.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No saved analyses yet. Confirmed AI drafts appear here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final message in state.messages)
                  Card(
                    child: ListTile(
                      key: ValueKey('smart-message-${message.id.value}'),
                      leading: const Icon(Icons.auto_awesome),
                      title: Text(
                        message.originalText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        message.createdAt != null
                            ? DateFormat.yMMMd().add_jm().format(
                                  message.createdAt!.value.toLocal(),
                                )
                            : formatSmartIntent(message.detectedIntent),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete analysis',
                        onPressed: () => context
                            .read<SmartInputCubit>()
                            .deleteMessage(message),
                      ),
                      onTap: () => _showDetails(context, message),
                    ),
                  ),
              ],
            ),
    };
  }

  void _showDetails(BuildContext context, SmartMessage message) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Text(
              'AI analysis',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Your note', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(message.originalText),
            const SizedBox(height: 12),
            Text('Detected intent', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(formatSmartIntent(message.detectedIntent)),
            if (message.extractedData.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Details', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              for (final entry in message.extractedData.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          entry.key,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(child: Text('${entry.value}')),
                    ],
                  ),
                ),
            ],
            if (message.suggestedActions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Suggested actions', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final action in message.suggestedActions)
                    if (_isActionableType(action.type))
                      ActionChip(
                        avatar: Icon(_actionTypeIcon(action.type), size: 18),
                        label: Text(formatSmartAction(action.type)),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          onAction(message, action.type);
                        },
                      )
                    else
                      Chip(
                        label: Text(formatSmartAction(action.type)),
                        visualDensity: VisualDensity.compact,
                      ),
                ],
              ),
            ],
            if (message.createdAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Saved '
                '${DateFormat.yMMMd().add_jm().format(message.createdAt!.value.toLocal())}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String formatSmartIntent(SmartMessageIntent intent) {
  return switch (intent) {
    SmartMessageIntent.addAllergy => 'Add allergy',
    SmartMessageIntent.addMedication => 'Add medication',
    SmartMessageIntent.addVaccination => 'Add vaccination',
    SmartMessageIntent.addSymptom => 'Add symptom',
    SmartMessageIntent.addVetVisit => 'Add vet visit',
    SmartMessageIntent.addReminder => 'Add reminder',
    SmartMessageIntent.addNote => 'Add note',
    SmartMessageIntent.unknown => 'Unknown',
  };
}

/// Whether tapping this suggested action performs something in the app.
bool _isActionableType(SmartSuggestedActionType type) =>
    type == SmartSuggestedActionType.createTimelineEvent ||
    type == SmartSuggestedActionType.createReminder;

IconData _actionTypeIcon(SmartSuggestedActionType type) =>
    type == SmartSuggestedActionType.createTimelineEvent
        ? Icons.timeline
        : Icons.notifications_active_outlined;

String formatSmartAction(SmartSuggestedActionType type) {
  return switch (type) {
    SmartSuggestedActionType.updatePetAllergies => 'Update pet allergies',
    SmartSuggestedActionType.createTimelineEvent => 'Create timeline event',
    SmartSuggestedActionType.createReminder => 'Create reminder',
    SmartSuggestedActionType.createDocument => 'Create document',
    SmartSuggestedActionType.updatePetNotes => 'Update pet notes',
    SmartSuggestedActionType.unknown => 'Unknown',
  };
}
