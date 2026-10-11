import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/app/router/app_router.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/presentation/widgets/adaptive_body.dart';
import 'package:paw_vault/core/presentation/widgets/adaptive_layout.dart';
import 'package:paw_vault/core/presentation/widgets/state_views.dart';
import 'package:paw_vault/core/subscription/presentation/cubit/subscription_cubit.dart';
import 'package:paw_vault/core/subscription/presentation/pro_gate.dart';
import 'package:paw_vault/features/account/presentation/widgets/account_action.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/presentation/cubit/pet_list_cubit.dart';
import 'package:paw_vault/features/pets/presentation/screens/pet_profile_screen.dart';

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

/// The pet list, and on a big enough surface the selected pet beside it.
///
/// The two-pane arrangement embeds [PetProfileScreen] directly rather than
/// routing to it. The screen takes a plain pet id -- its `@PathParam` only
/// tells the generator how to fill that id from a URL -- so it works as a
/// widget, and the router stays the flat stack it already was. Everything the
/// profile leads on to, the timeline and the documents and the rest, still
/// pushes a full-screen route from either arrangement.
class _PetListView extends StatefulWidget {
  const _PetListView();

  @override
  State<_PetListView> createState() => _PetListViewState();
}

class _PetListViewState extends State<_PetListView> {
  /// Null until something is picked, and held by id rather than by index so
  /// that adding or removing a pet cannot silently move the selection.
  String? _selectedPetId;

  /// Free users can keep [kFreePetLimit] pets; adding more opens the paywall.
  Future<void> _onAddPet(BuildContext context, int petCount) async {
    final isPro = context.read<SubscriptionCubit>().isPro;
    if (!isPro && petCount >= kFreePetLimit) {
      final unlocked = await showPaywall(context);
      if (!unlocked) return;
    }
    if (context.mounted) context.router.push(PetFormRoute());
  }

  /// The pet the detail pane shows: what was picked while it still exists,
  /// and otherwise the first, so the pane is never blank when there is
  /// something to put in it. Resolved during build instead of being written
  /// back to state, which keeps a deleted pet from leaving a stale id behind.
  String? _shownPetId(List<Pet> pets) {
    if (pets.isEmpty) return null;
    final picked = _selectedPetId;
    if (picked != null && pets.any((pet) => pet.id.value == picked)) {
      return picked;
    }
    return pets.first.id.value;
  }

  @override
  Widget build(BuildContext context) {
    final twoPanes = hasRoomForTwoPanes(MediaQuery.sizeOf(context));

    return Scaffold(
      appBar: AppBar(
        title: const Text('PawVault'),
        actions: const [AccountAction()],
      ),
      body: BlocBuilder<PetListCubit, PetListState>(
        builder: (context, state) {
          final list = switch (state.status) {
            PetListStatus.initial ||
            PetListStatus.loading =>
              const LoadingView(),
            PetListStatus.failure => ErrorStateView(
                title: 'Could not load pets',
                message: state.errorMessage,
              ),
            PetListStatus.ready => state.pets.isEmpty
                ? const EmptyStateView(
                    icon: Icons.pets,
                    title: 'No pets yet',
                    message: 'Add your first pet profile to start building '
                        'a health archive.',
                  )
                : _PetListContent(
                    pets: state.pets,
                    selectedPetId: twoPanes ? _shownPetId(state.pets) : null,
                    onSelect: twoPanes
                        ? (pet) => setState(() => _selectedPetId = pet.id.value)
                        : null,
                  ),
          };

          if (!twoPanes) return AdaptiveBody(child: list);

          final shown = _shownPetId(state.pets);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: twoPaneListWidth,
                // Its own Scaffold so that adding a pet sits inside the pane
                // it belongs to. Hung off the outer one it floated over the
                // profile instead, covering whatever was at that corner.
                child: Scaffold(
                  body: SafeArea(right: false, child: list),
                  floatingActionButton: _addPetButton(context, state),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: shown == null
                    ? const SafeArea(
                        left: false,
                        child: EmptyStateView(
                          icon: Icons.pets,
                          title: 'No pet selected',
                          message: 'Pick a pet to see its health archive.',
                        ),
                      )
                    // Keyed so that picking another pet rebuilds the profile
                    // against the new id rather than reusing the old state.
                    : PetProfileScreen(key: ValueKey(shown), petId: shown),
              ),
            ],
          );
        },
      ),
      floatingActionButton: twoPanes
          ? null
          : BlocBuilder<PetListCubit, PetListState>(builder: _addPetButton),
    );
  }

  Widget _addPetButton(BuildContext context, PetListState state) {
    return FloatingActionButton.extended(
      onPressed: () => _onAddPet(context, state.pets.length),
      icon: const Icon(Icons.add),
      label: const Text('Add pet'),
    );
  }
}

class _PetListContent extends StatelessWidget {
  const _PetListContent({
    required this.pets,
    this.selectedPetId,
    this.onSelect,
  });

  final List<Pet> pets;

  /// Set only in the two-pane arrangement, where a row is a choice rather
  /// than a way out of this screen.
  final String? selectedPetId;
  final void Function(Pet pet)? onSelect;

  @override
  Widget build(BuildContext context) {
    final select = onSelect;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        select == null ? 16 : twoPaneListBottomInset,
      ),
      itemCount: pets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final pet = pets[index];
        final isSelected = pet.id.value == selectedPetId;
        return Card(
          child: ListTile(
            key: ValueKey('pet-${pet.id.value}'),
            selected: isSelected,
            leading: const CircleAvatar(
              child: Icon(Icons.pets),
            ),
            title: Text(pet.name),
            subtitle: Text(_petSubtitle(pet)),
            // A chevron says "this leaves here", which is only true when a
            // tap pushes the profile as its own screen.
            trailing: select == null ? const Icon(Icons.chevron_right) : null,
            onTap: () {
              if (select != null) {
                select(pet);
                return;
              }
              context.router.push(PetProfileRoute(petId: pet.id.value));
            },
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
