# Phase 4 Pet List Screen States

## Scope

Updated the pet list screen to render repository-backed states from
`PetListCubit`.

## Implementation

Updated:

```text
lib/features/pets/presentation/screens/pet_list_screen.dart
```

The screen now renders:

- loading state
- empty state
- failure state
- populated list state

The screen still does not implement create, edit, delete, or navigation actions.
Those remain separate Phase 4 tasks.

## Tests

Created:

```text
test/features/pets/presentation/screens/pet_list_screen_test.dart
```

Coverage includes:

- loading rendering
- empty rendering
- populated list rendering
- error rendering
