import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/app/router/app_router.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/presentation/cubit/pet_profile_cubit.dart';

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
                if (state.status == PetProfileStatus.ready &&
                    state.pet != null) {
                  return IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: state.status == PetProfileStatus.deleting
                        ? null
                        : () => _showDeleteConfirmation(context),
                    tooltip: 'Delete pet',
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
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
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
                      child: CircleAvatar(
                        radius: 64,
                        backgroundImage: NetworkImage(pet.photoUrl.toString()),
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
                      if (pet.birthDate != null)
                        _InfoRow('Birth Date', pet.birthDate.toString()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (pet.weight != null) ...[
                    _buildInfoCard(
                      context,
                      'Physical Details',
                      [
                        _InfoRow(
                          'Weight',
                          '${pet.weight!.value} ${pet.weight!.unit.name}',
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
    final entries = <(IconData, String, PageRouteInfo)>[
      (Icons.timeline, 'Timeline', TimelineRoute(petId: petId)),
      (Icons.folder, 'Documents', DocumentsRoute(petId: petId)),
      (Icons.notifications, 'Reminders', RemindersRoute(petId: petId)),
      (Icons.bolt, 'Smart Input', SmartInputRoute(petId: petId)),
      (
        Icons.summarize,
        'Vet Summary Export',
        VetSummaryExportRoute(petId: petId),
      ),
    ];

    return Card(
      child: Column(
        children: [
          for (final (icon, label, route) in entries)
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.router.push(route),
            ),
        ],
      ),
    );
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
            ...rows.map((row) => Padding(
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Text(row.value),
                            ),
                          ],
                        ),
                )),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;
}
