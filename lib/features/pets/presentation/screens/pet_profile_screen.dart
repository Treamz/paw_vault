import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/app/router/app_router.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/presentation/widgets/full_screen_image.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/core/subscription/presentation/cubit/subscription_cubit.dart';
import 'package:paw_vault/core/subscription/presentation/pro_gate.dart';
import 'package:paw_vault/core/utils/parse_decimal.dart';
import 'package:paw_vault/features/account/domain/repositories/owner_profile_repository.dart';
import 'package:paw_vault/features/pets/application/pet_photo_upload_service.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/repositories/weight_entry_repository.dart';
import 'package:paw_vault/features/pets/presentation/cubit/pet_profile_cubit.dart';
import 'package:paw_vault/features/pets/presentation/models/pet_measurement_labels.dart';

@RoutePage()
class PetProfileScreen extends StatelessWidget {
  const PetProfileScreen({
    @PathParam('petId') required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PetProfileCubit(
        petRepository: context.read<PetRepository>(),
        authRepository: context.read<AuthRepository>(),
        photoUploadService: PetPhotoUploadService(
          storageRepository: context.read<StorageRepository>(),
        ),
        ownerProfileRepository: context.read<OwnerProfileRepository>(),
        weightEntryRepository: context.read<WeightEntryRepository>(),
      )..load(petId),
      child: const _PetProfileView(),
    );
  }
}

class _PetProfileView extends StatelessWidget {
  const _PetProfileView();

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet'),
        content: const Text(
          'Are you sure you want to delete this pet? This action cannot be undone.',
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
      context.read<PetProfileCubit>().deletePet();
    }
  }

  Future<void> _openEdit(BuildContext context, String petId) async {
    final cubit = context.read<PetProfileCubit>();
    await context.router.push(PetFormRoute(petId: petId));
    await cubit.load(petId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PetProfileCubit, PetProfileState>(
      listener: (context, state) {
        if (state.status == PetProfileStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pet deleted successfully')),
          );
          context.router.back();
        }

        if (state.status == PetProfileStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pet Profile'),
          actions: [
            BlocBuilder<PetProfileCubit, PetProfileState>(
              builder: (context, state) {
                final pet = state.pet;
                if (state.status == PetProfileStatus.ready && pet != null) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _openEdit(context, pet.id.value),
                        tooltip: 'Edit pet',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _showDeleteConfirmation(context),
                        tooltip: 'Delete pet',
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<PetProfileCubit, PetProfileState>(
          builder: (context, state) {
            if (state.status == PetProfileStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state.status == PetProfileStatus.notFound) {
              return const Center(
                child: Text('Pet not found'),
              );
            }

            if (state.status == PetProfileStatus.failure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading pet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              );
            }

            final pet = state.pet;
            if (pet == null) {
              return const Center(
                child: Text('No pet data available'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pet.photoUrl != null) ...[
                    Center(
                      child: GestureDetector(
                        onTap: () => showFullScreenImage(
                          context,
                          CachedNetworkImageProvider(
                            pet.photoUrl.toString(),
                          ),
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: pet.photoUrl.toString(),
                            width: 128,
                            height: 128,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 150),
                            placeholder: (context, url) =>
                                _photoPlaceholder(context),
                            errorWidget: (context, url, error) =>
                                _photoPlaceholder(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildRecordsCard(context, pet.id.value),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    'Basic Information',
                    [
                      _InfoRow('Name', pet.name),
                      if (pet.species != null)
                        _InfoRow('Species', pet.species!),
                      if (pet.breed != null) _InfoRow('Breed', pet.breed!),
                      if (pet.gender != null)
                        _InfoRow(
                          'Gender',
                          pet.gender!.name[0].toUpperCase() +
                              pet.gender!.name.substring(1),
                        ),
                      _InfoRow(
                        'Birth Date',
                        pet.birthDate != null
                            ? DateFormat.yMMMd()
                                .format(pet.birthDate!.toUtcDateTime())
                            : 'Not set',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildOwnerCard(context, state),
                  const SizedBox(height: 16),
                  if (pet.weight != null || pet.measurements.isNotEmpty) ...[
                    _buildInfoCard(
                      context,
                      'Physical Details',
                      [
                        if (pet.weight != null)
                          _InfoRow(
                            'Weight',
                            '${formatDecimal(pet.weight!.value)} '
                                '${pet.weight!.unit.name}',
                          ),
                        for (final measurement in pet.measurements)
                          _InfoRow(
                            measurement.type.label,
                            '${_formatCm(measurement.valueCm)} cm',
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (pet.microchipNumber != null) ...[
                    _buildInfoCard(
                      context,
                      'Identification',
                      [
                        _InfoRow('Microchip Number', pet.microchipNumber!),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (pet.allergies.isNotEmpty ||
                      pet.chronicConditions.isNotEmpty) ...[
                    _buildInfoCard(
                      context,
                      'Health Information',
                      [
                        if (pet.allergies.isNotEmpty)
                          _InfoRow('Allergies', pet.allergies.join(', ')),
                        if (pet.chronicConditions.isNotEmpty)
                          _InfoRow(
                            'Chronic Conditions',
                            pet.chronicConditions.join(', '),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (pet.notes != null) ...[
                    _buildInfoCard(
                      context,
                      'Notes',
                      [
                        _InfoRow('', pet.notes!),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecordsCard(BuildContext context, String petId) {
    // The last flag marks Pro-only (AI) destinations.
    final entries = <(IconData, String, PageRouteInfo, bool)>[
      (Icons.timeline, 'Timeline', TimelineRoute(petId: petId), false),
      (
        Icons.monitor_weight_outlined,
        'Weight',
        WeightHistoryRoute(petId: petId),
        false,
      ),
      (Icons.folder, 'Documents', DocumentsRoute(petId: petId), false),
      (Icons.notifications, 'Reminders', RemindersRoute(petId: petId), false),
      (Icons.bolt, 'Smart Input', SmartInputRoute(petId: petId), true),
      (
        Icons.summarize,
        'Vet Summary Export',
        VetSummaryExportRoute(petId: petId),
        false,
      ),
    ];
    final isPro = context.watch<SubscriptionCubit>().isPro;

    return Card(
      child: Column(
        children: [
          for (final (icon, label, route, requiresPro) in entries)
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: requiresPro && !isPro
                  ? const Icon(Icons.lock_outline)
                  : const Icon(Icons.chevron_right),
              onTap: () => _openRecord(context, route, requiresPro),
            ),
        ],
      ),
    );
  }

  Future<void> _openRecord(
    BuildContext context,
    PageRouteInfo route,
    bool requiresPro,
  ) async {
    if (requiresPro && !context.read<SubscriptionCubit>().isPro) {
      final unlocked = await showPaywall(context);
      if (!unlocked) return;
    }
    if (context.mounted) context.router.push(route);
  }

  Widget _photoPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 128,
      height: 128,
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.pets, size: 48, color: colorScheme.onSurfaceVariant),
    );
  }

  String _formatCm(double value) => formatDecimal(value);

  Widget _buildOwnerCard(BuildContext context, PetProfileState state) {
    final owner = state.owner;
    final profile = state.ownerProfile;
    final name = profile?.name ??
        (owner != null && !owner.isAnonymous ? owner.displayName : null);
    final email = owner != null && !owner.isAnonymous ? owner.email : null;
    final phone = profile?.phone;
    final hasDetails = name != null || email != null || phone != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Owner Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit owner information',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _editOwnerInfo(context, state),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (name != null)
              _buildInfoRowWidget(context, _InfoRow('Name', name)),
            if (email != null)
              _buildInfoRowWidget(
                context,
                _InfoRow('Email', email, singleLine: true),
              ),
            if (phone != null)
              _buildInfoRowWidget(context, _InfoRow('Phone', phone)),
            if (!hasDetails)
              Text(
                'Add your contact details so vets can reach you.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editOwnerInfo(
    BuildContext context,
    PetProfileState state,
  ) async {
    final cubit = context.read<PetProfileCubit>();
    final result = await showDialog<({String name, String phone})>(
      context: context,
      builder: (_) => _OwnerInfoDialog(
        initialName: state.ownerProfile?.name ?? state.owner?.displayName ?? '',
        initialPhone: state.ownerProfile?.phone ?? '',
      ),
    );

    if (result != null) {
      await cubit.saveOwnerInfo(name: result.name, phone: result.phone);
    }
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    List<_InfoRow> rows,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...rows.map((row) => _buildInfoRowWidget(context, row)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRowWidget(BuildContext context, _InfoRow row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: row.label.isEmpty
          ? Text(row.value)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    row.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Expanded(
                  child: row.singleLine
                      // Scale down instead of wrapping so long values such
                      // as emails stay on one line.
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(row.value, maxLines: 1),
                        )
                      : Text(row.value),
                ),
              ],
            ),
    );
  }
}

/// Owns its controllers so they outlive the dialog's exit animation.
class _OwnerInfoDialog extends StatefulWidget {
  const _OwnerInfoDialog({
    required this.initialName,
    required this.initialPhone,
  });

  final String initialName;
  final String initialPhone;

  @override
  State<_OwnerInfoDialog> createState() => _OwnerInfoDialogState();
}

class _OwnerInfoDialogState extends State<_OwnerInfoDialog> {
  late final _nameController = TextEditingController(text: widget.initialName);
  late final _phoneController =
      TextEditingController(text: widget.initialPhone);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Owner Information'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            (name: _nameController.text, phone: _phoneController.text),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value, {this.singleLine = false});

  final String label;
  final String value;

  /// Keep the value on a single line, scaling it down to fit (e.g. emails).
  final bool singleLine;
}
