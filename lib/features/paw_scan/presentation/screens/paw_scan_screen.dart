import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/app/router/app_router.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/presentation/widgets/state_views.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/paw_scan/application/paw_photo_upload_service.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_scan_draft.dart';
import 'package:paw_vault/features/paw_scan/domain/paw_scan_copy.dart';
import 'package:paw_vault/features/paw_scan/domain/repositories/paw_check_repository.dart';
import 'package:paw_vault/features/paw_scan/domain/repositories/paw_scan_ai_repository.dart';
import 'package:paw_vault/features/paw_scan/domain/services/paw_photo_picker.dart';
import 'package:paw_vault/features/paw_scan/domain/services/paw_scan_reminder_suggestion.dart';
import 'package:paw_vault/features/paw_scan/presentation/cubit/paw_scan_cubit.dart';
import 'package:paw_vault/features/paw_scan/presentation/widgets/paw_attention_badge.dart';
import 'package:paw_vault/features/paw_scan/presentation/widgets/paw_scan_disclaimer.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';

@RoutePage()
class PawScanScreen extends StatelessWidget {
  const PawScanScreen({
    @PathParam('petId') required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PawScanCubit(
        pawCheckRepository: context.read<PawCheckRepository>(),
        aiRepository: context.read<PawScanAiRepository>(),
        petRepository: context.read<PetRepository>(),
        picker: context.read<PawPhotoPicker>(),
        authRepository: context.read<AuthRepository>(),
        uploadService: PawPhotoUploadService(
          storageRepository: context.read<StorageRepository>(),
        ),
        analytics: context.read<AnalyticsService>(),
      )..load(petId),
      child: _PawScanView(petId: petId),
    );
  }
}

class _PawScanView extends StatefulWidget {
  const _PawScanView({required this.petId});

  final String petId;

  @override
  State<_PawScanView> createState() => _PawScanViewState();
}

class _PawScanViewState extends State<_PawScanView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);
  final _noteController = TextEditingController();
  bool _includeInVetSummary = false;

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<PawPhotoSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(PawPhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from library'),
              onTap: () => Navigator.of(context).pop(PawPhotoSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;
    await context.read<PawScanCubit>().addPhoto(source);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paw Scan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Scan'),
            Tab(text: 'Journal'),
          ],
        ),
      ),
      body: BlocConsumer<PawScanCubit, PawScanState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == PawScanStatus.saved) {
            _noteController.clear();
            setState(() => _includeInVetSummary = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Paw check saved to the journal'),
                action: SnackBarAction(
                  label: 'View',
                  onPressed: () => _tabController.animateTo(1),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildScanTab(context, state),
              _JournalTab(state: state, petName: state.petName),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScanTab(BuildContext context, PawScanState state) {
    final cubit = context.read<PawScanCubit>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Always first, and always present — before capture, during review,
        // and on a rejection.
        const PawScanDisclaimer(),
        const SizedBox(height: 16),
        if (state.status == PawScanStatus.failure &&
            state.errorMessage != null) ...[
          _ErrorBanner(message: state.errorMessage!),
          const SizedBox(height: 16),
        ],
        if (state.status == PawScanStatus.rejected && state.draft != null) ...[
          _RejectionNotice(
            title: formatPawRejectionTitle(state.draft!),
            message: formatPawRejectionMessage(state.draft!),
            isUrgent: state.draft!.status == PawScanDraftStatus.blocked,
          ),
          const SizedBox(height: 16),
        ],
        if (state.hasResult) ...[
          _ResultSection(
            state: state,
            noteController: _noteController,
            includeInVetSummary: _includeInVetSummary,
            onIncludeChanged: (value) =>
                setState(() => _includeInVetSummary = value),
            onLog: () => cubit.logCheck(
              widget.petId,
              ownerNote: _noteController.text,
              includeInVetSummary: _includeInVetSummary,
            ),
            onDiscard: cubit.discardDraft,
          ),
          const SizedBox(height: 24),
        ],
        Text('Which paw?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _PawLocationSelector(
          location: state.location,
          onChanged: state.isBusy ? null : cubit.setLocation,
        ),
        const SizedBox(height: 16),
        if (state.hasPhotos) ...[
          _PhotoStrip(
            state: state,
            onRemove: state.isBusy ? null : cubit.removePhoto,
          ),
          const SizedBox(height: 12),
        ] else ...[
          Text(
            PawScanCopy.captureTips,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
        ],
        OutlinedButton.icon(
          onPressed: state.canAddPhoto ? _addPhoto : null,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(state.hasPhotos ? 'Add another paw' : 'Add paw photo'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: state.canAnalyze ? cubit.analyze : null,
          icon: state.status == PawScanStatus.analyzing
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: Text(
            state.status == PawScanStatus.analyzing
                ? 'Describing…'
                : 'Describe ${state.photos.length} photo'
                    '${state.photos.length == 1 ? '' : 's'}',
          ),
        ),
      ],
    );
  }
}

class _PawLocationSelector extends StatelessWidget {
  const _PawLocationSelector({required this.location, this.onChanged});

  final PawLocation location;
  final ValueChanged<PawLocation>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in PawLocation.values)
          ChoiceChip(
            label: Text(formatPawLocation(option)),
            selected: option == location,
            onSelected:
                onChanged == null ? null : (_) => onChanged!.call(option),
          ),
      ],
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.state, this.onRemove});

  final PawScanState state;
  final ValueChanged<int>? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.photos.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  state.photos[index].bytes,
                  height: 96,
                  width: 96,
                  fit: BoxFit.cover,
                ),
              ),
              if (onRemove != null)
                Positioned(
                  top: -8,
                  right: -8,
                  child: IconButton(
                    tooltip: 'Remove photo ${index + 1}',
                    icon: const Icon(Icons.cancel),
                    onPressed: () => onRemove!.call(index),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.state,
    required this.noteController,
    required this.includeInVetSummary,
    required this.onIncludeChanged,
    required this.onLog,
    required this.onDiscard,
  });

  final PawScanState state;
  final TextEditingController noteController;
  final bool includeInVetSummary;
  final ValueChanged<bool> onIncludeChanged;
  final VoidCallback onLog;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = state.draft!;
    final isSaving = state.status == PawScanStatus.saving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PawAttentionCard(level: draft.attentionLevel),
        const SizedBox(height: 16),
        // Repeated next to the observations: a notice at the top of a
        // scrolling screen is off-screen by the time the descriptions are
        // read, which is exactly when it matters.
        const PawScanDisclaimer(),
        const SizedBox(height: 16),
        if (draft.isLowConfidence)
          const _Notice(message: PawScanCopy.lowConfidenceNotice),
        if (draft.safetyFilterApplied)
          const _Notice(message: PawScanCopy.safetyFilteredNotice),
        Text('What Paw Scan can see', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (!draft.hasObservations)
          Text(
            'Nothing in these photos stood out.',
            style: theme.textTheme.bodyMedium,
          )
        else
          for (final observation in draft.observations)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 6),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '${formatPawObservationArea(observation.area)}: ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: observation.text,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        if (draft.summary != null) ...[
          const SizedBox(height: 8),
          Text(draft.summary!, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 16),
        Text(
          PawScanCopy.nothingSavedYet,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: noteController,
          enabled: !isSaving,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 3,
          minLines: 2,
          decoration: const InputDecoration(
            labelText: 'Anything you noticed yourself? (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        SwitchListTile(
          value: includeInVetSummary,
          onChanged: isSaving ? null : onIncludeChanged,
          contentPadding: EdgeInsets.zero,
          title: const Text('Include in the vet summary'),
          subtitle: const Text(
            'Adds these descriptions to the exported PDF.',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSaving ? null : onDiscard,
                icon: const Icon(Icons.close),
                label: const Text('Discard'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: isSaving ? null : onLog,
                icon: isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(isSaving ? 'Saving…' : 'Log this check'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_outlined,
            size: 18,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _RejectionNotice extends StatelessWidget {
  const _RejectionNotice({
    required this.title,
    required this.message,
    required this.isUrgent,
  });

  final String title;
  final String message;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isUrgent
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = isUrgent
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSurfaceVariant;

    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUrgent ? Icons.priority_high : Icons.photo_camera_outlined,
                  color: foreground,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalTab extends StatelessWidget {
  const _JournalTab({required this.state, required this.petName});

  final PawScanState state;
  final String petName;

  @override
  Widget build(BuildContext context) {
    return switch (state.journalStatus) {
      PawJournalStatus.loading => const LoadingView(),
      PawJournalStatus.failure => ErrorStateView(
          title: 'Could not load the journal',
          message: state.journalError ?? 'Please try again.',
        ),
      PawJournalStatus.ready => state.checks.isEmpty
          ? const EmptyStateView(
              icon: Icons.pets,
              title: 'No paw checks yet',
              message: 'Photograph a paw on the Scan tab to start a record '
                  'you can show your vet.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.checks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final check = state.checks[index];
                return _PawCheckTile(
                  check: check,
                  petName: petName,
                  // Checks are newest first, so the comparison target is the
                  // next one down that is the same paw.
                  previousForSamePaw: state.checks
                      .skip(index + 1)
                      .where((other) => other.location == check.location)
                      .firstOrNull,
                );
              },
            ),
    };
  }
}

class _PawCheckTile extends StatelessWidget {
  const _PawCheckTile({
    required this.check,
    required this.petName,
    this.previousForSamePaw,
  });

  final PawCheck check;
  final String petName;

  /// The most recent earlier check of the same paw, when there is one.
  final PawCheck? previousForSamePaw;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateFormat.yMMMd().format(check.checkedAt.value.toLocal());
    // Computed on-device from the attention level, then handed to the real
    // reminder form: nothing is scheduled until the owner saves it.
    final suggestion = PawScanReminderSuggestion.forCheck(
      check,
      petName: petName,
      now: DateTime.now(),
    );

    return Card(
      key: ValueKey('paw-check-${check.id.value}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$date · ${formatPawLocation(check.location)}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                PawAttentionBadge(level: check.attentionLevel),
              ],
            ),
            if (check.observations.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                check.observations.first,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (check.ownerNote != null) ...[
              const SizedBox(height: 8),
              Text(
                'Your note: ${check.ownerNote}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: FilterChip(
                    label: const Text('In vet summary'),
                    selected: check.includeInVetSummary,
                    visualDensity: VisualDensity.compact,
                    onSelected: (value) => context
                        .read<PawScanCubit>()
                        .setIncludeInVetSummary(check, include: value),
                  ),
                ),
                const Spacer(),
                if (previousForSamePaw != null)
                  IconButton(
                    tooltip: 'Compare with the previous check of this paw',
                    icon: const Icon(Icons.compare_arrows),
                    onPressed: () => context.router.push(
                      PawCheckComparisonRoute(
                        earlier: previousForSamePaw!,
                        later: check,
                      ),
                    ),
                  ),
                if (suggestion != null)
                  TextButton.icon(
                    onPressed: () => context.router.push(
                      ReminderFormRoute(
                        petId: check.petId.value,
                        initialTitle: suggestion.title,
                        initialDescription: suggestion.description,
                        initialDateTimeIso:
                            suggestion.dateTime.toIso8601String(),
                      ),
                    ),
                    icon: const Icon(Icons.alarm_add_outlined),
                    label: const Text('Follow up'),
                  ),
                IconButton(
                  tooltip: 'Delete this check',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      context.read<PawScanCubit>().deleteCheck(check),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
