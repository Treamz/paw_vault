import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';
import 'package:paw_vault/features/smart_input/presentation/cubit/smart_input_cubit.dart';

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
      create: (context) =>
          SmartInputCubit(context.read<SmartInputRepository>()),
      child: const _SmartInputView(),
    );
  }
}

class _SmartInputView extends StatefulWidget {
  const _SmartInputView();

  @override
  State<_SmartInputView> createState() => _SmartInputViewState();
}

class _SmartInputViewState extends State<_SmartInputView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Input')),
      body: SafeArea(
        child: BlocBuilder<SmartInputCubit, SmartInputState>(
          builder: (context, state) {
            final isProcessing = state.isProcessing;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _controller,
                    enabled: !isProcessing,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Describe what happened',
                      hintText: 'e.g. Bella got her rabies shot today',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () => context
                            .read<SmartInputCubit>()
                            .submit(_controller.text),
                    icon: isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(isProcessing ? 'Analyzing…' : 'Analyze'),
                  ),
                  const SizedBox(height: 16),
                  if (state.status == SmartInputStatus.failure &&
                      state.errorMessage != null)
                    _ErrorBanner(message: state.errorMessage!),
                  if (state.hasDraft) _DraftReview(draft: state.draft!),
                ],
              ),
            );
          },
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
            Icon(Icons.error_outline,
                color: theme.colorScheme.onErrorContainer),
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

class _DraftReview extends StatelessWidget {
  const _DraftReview({required this.draft});

  final SmartInputDraft draft;

  bool get _isLowConfidence =>
      draft.status == SmartInputDraftStatus.lowConfidenceReview ||
      (draft.confidence != null && draft.confidence! < 0.6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            const SizedBox(height: 12),
            _Field('Detected intent', _formatIntent(draft.detectedIntent)),
            if (draft.extractedData.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Extracted data', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              for (final entry in draft.extractedData.entries)
                _Field(entry.key, '${entry.value}'),
            ],
            if (draft.suggestedActions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Suggested actions', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              for (final action in draft.suggestedActions)
                Row(
                  children: [
                    const Icon(Icons.arrow_right),
                    Expanded(child: Text(_formatActionType(action.type))),
                  ],
                ),
            ],
            if (_isLowConfidence) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.warning_amber,
                      size: 18, color: theme.colorScheme.error),
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
            const SizedBox(height: 12),
            Text(
              'AI-generated from your text. Review carefully; nothing is saved '
              'until you confirm.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatIntent(SmartMessageIntent intent) {
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

  String _formatActionType(SmartSuggestedActionType type) {
    return switch (type) {
      SmartSuggestedActionType.updatePetAllergies => 'Update pet allergies',
      SmartSuggestedActionType.createTimelineEvent => 'Create timeline event',
      SmartSuggestedActionType.createReminder => 'Create reminder',
      SmartSuggestedActionType.createDocument => 'Create document',
      SmartSuggestedActionType.updatePetNotes => 'Update pet notes',
      SmartSuggestedActionType.unknown => 'Unknown',
    };
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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
