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
        if (state.hasPhotos) ...[
          _PhotoStrip(
            state: state,
            onRemove: state.isBusy ? null : cubit.removePhoto,
          ),
          const SizedBox(height: 16),
          // Asked only once there is a photo to label. Before that it is a
          // question about nothing.
          Text('Which paw?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _PawLocationSelector(
            location: state.location,
            onChanged: state.isBusy ? null : cubit.setLocation,
          ),
          const SizedBox(height: 16),
        ] else ...[
          // Above the buttons on purpose: one tap now opens the camera, so
          // this is the only moment the owner can read the framing advice
          // before shooting.
          Text(
            PawScanCopy.captureTips,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
        ],
        _CaptureActions(
          state: state,
          onCamera: () => cubit.addPhoto(PawPhotoSource.camera),
          onGallery: () => cubit.addPhoto(PawPhotoSource.gallery),
          onAnalyze: cubit.analyze,
        ),
      ],
    );
  }
}

/// The capture and analyse actions, with the emphasis on whichever one is the
/// owner's likely next step.
///
/// Both sources are one tap. There is no source-picker sheet: choosing between
/// two options does not need a screen of its own, and the camera is what the
/// owner came here for — often one-handed, while holding the animal still.
class _CaptureActions extends StatelessWidget {
  const _CaptureActions({
    required this.state,
    required this.onCamera,
    required this.onGallery,
    required this.onAnalyze,
  });

  final PawScanState state;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final canCapture = state.canAddPhoto;

    if (!state.hasPhotos) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: canCapture ? onCamera : null,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text(PawScanCopy.takePhoto),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: canCapture ? onGallery : null,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text(PawScanCopy.chooseFromGallery),
          ),
        ],
      );
    }

    // Describing the same photos the model already rejected cannot produce a
    // different answer, so the emphasis goes back to the camera.
    final captureIsPrimary = state.status == PawScanStatus.rejected;
    final analyze = _AnalyzeButton(
      state: state,
      onPressed: state.canAnalyze ? onAnalyze : null,
      isPrimary: !captureIsPrimary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (captureIsPrimary) ...[
          FilledButton.icon(
            onPressed: canCapture ? onCamera : null,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text(PawScanCopy.takeAnotherPhoto),
          ),
          const SizedBox(height: 12),
          analyze,
        ] else ...[
          analyze,
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: canCapture ? onCamera : null,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text(PawScanCopy.camera),
              ),
              OutlinedButton.icon(
                onPressed: canCapture ? onGallery : null,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text(PawScanCopy.gallery),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AnalyzeButton extends StatelessWidget {
  const _AnalyzeButton({
    required this.state,
    required this.onPressed,
    required this.isPrimary,
  });

  final PawScanState state;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final isAnalyzing = state.status == PawScanStatus.analyzing;
    final icon = isAnalyzing
        ? const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.search);
    final label = Text(
      isAnalyzing
          ? PawScanCopy.describing
          : PawScanCopy.describePhotos(state.photos.length),
    );

    if (isPrimary) {
      return FilledButton.icon(onPressed: onPressed, icon: icon, label: label);
    }

    return OutlinedButton.icon(onPressed: onPressed, icon: icon, label: label);
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
            // Stacked, not side by side: "Sep 19, 2026 · Not sure" and
            // "Worth showing a vet soon" both run long, and on a narrow phone
            // they overflowed a Row by 34px. Giving each its own line costs a
            // little height and cannot break.
            Text(
              '$date · ${formatPawLocation(check.location)}',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: PawAttentionBadge(level: check.attentionLevel),
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
            // A Wrap, not a Row: the chip plus up to three actions do not fit
            // on one line on a narrow phone (it overflowed by 13px with only
            // two of them), and they fit even less at a larger font scale.
            // Wrapping to a second line degrades gracefully; a Row clips.
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    label: const Text('In vet summary'),
                    selected: check.includeInVetSummary,
                    visualDensity: VisualDensity.compact,
                    onSelected: (value) => context
                        .read<PawScanCubit>()
                        .setIncludeInVetSummary(check, include: value),
                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}
