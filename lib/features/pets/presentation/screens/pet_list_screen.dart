import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/app/router/app_router.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/features/account/presentation/widgets/account_action.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/presentation/cubit/pet_list_cubit.dart';

@RoutePage()
class PetListScreen extends StatelessWidget {
  const PetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PetListCubit(
        petRepository: context.read<PetRepository>(),
        authRepository: context.read<AuthRepository>(),
      )..load(),
      child: const _PetListView(),
    );
  }
}

class _PetListView extends StatelessWidget {
  const _PetListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PawVault'),
        actions: const [AccountAction()],
      ),
      body: SafeArea(
        child: BlocBuilder<PetListCubit, PetListState>(
          builder: (context, state) {
            return switch (state.status) {
              PetListStatus.initial ||
              PetListStatus.loading =>
                const _PetListLoading(),
              PetListStatus.failure => _PetListFailure(
                  message: state.errorMessage,
                ),
              PetListStatus.ready => state.pets.isEmpty
                  ? const _PetListEmpty()
                  : _PetListContent(pets: state.pets),
            };
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.router.push(PetFormRoute()),
        icon: const Icon(Icons.add),
        label: const Text('Add pet'),
      ),
    );
  }
}

class _PetListLoading extends StatelessWidget {
  const _PetListLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _PetListEmpty extends StatelessWidget {
  const _PetListEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pets,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No pets yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first pet profile to start building a health archive.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PetListFailure extends StatelessWidget {
  const _PetListFailure({required this.message});

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
              'Could not load pets',
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

class _PetListContent extends StatelessWidget {
  const _PetListContent({required this.pets});

  final List<Pet> pets;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final pet = pets[index];
        return Card(
          child: ListTile(
            key: ValueKey('pet-${pet.id.value}'),
            leading: const CircleAvatar(
              child: Icon(Icons.pets),
            ),
            title: Text(pet.name),
            subtitle: Text(_petSubtitle(pet)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.router.push(
              PetProfileRoute(petId: pet.id.value),
            ),
          ),
        );
      },
    );
  }

  String _petSubtitle(Pet pet) {
    final parts = [
      pet.species,
      pet.breed,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();

    if (parts.isEmpty) {
      return 'Pet profile';
    }

    return parts.join(' - ');
  }
}
