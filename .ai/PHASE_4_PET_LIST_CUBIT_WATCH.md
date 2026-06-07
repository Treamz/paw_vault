# Phase 4 PetListCubit Watch

## Scope

Added the Phase 4 task checklist and implemented the first Pet CRUD behavior:
`PetListCubit` now loads the current user and watches pets through
`PetRepository`.

## Implementation

Updated:

```text
lib/features/pets/presentation/cubit/pet_list_cubit.dart
lib/features/pets/presentation/screens/pet_list_screen.dart
```

The Cubit now:

- initializes `PetRepository`
- resolves the current user through `AuthRepository`
- signs in anonymously if no current user exists
- subscribes to `PetRepository.watchPets(...)`
- exposes initial, loading, ready, and failure states
- cancels the repository stream subscription on close

## Tests

Created:

```text
test/features/pets/presentation/cubit/pet_list_cubit_test.dart
```

Coverage includes:

- loading current user and watched pets
- anonymous sign-in fallback
- failure state when loading fails
