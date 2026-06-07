# PawVault Navigation Flow

This document describes how to move between every screen in the app, the route
each screen is registered under, and how to verify the flows against a running
app. Routes are defined in `lib/app/router/app_router.dart` (AutoRoute).

## Screen map

```
PetListScreen  (/)                         ← initial / home
├── [FAB "Add pet"]            → PetFormScreen        (/pets/form)            (create)
└── [tap a pet tile]           → PetProfileScreen     (/pets/:petId)
        ├── [AppBar trash icon] → delete confirm dialog → back to PetListScreen
        └── Records card:
            ├── Timeline            → TimelineScreen           (/pets/:petId/timeline)
            ├── Documents           → DocumentsScreen          (/pets/:petId/documents)
            ├── Reminders           → RemindersScreen          (/pets/:petId/reminders)          [placeholder]
            ├── Smart Input         → SmartInputScreen         (/pets/:petId/smart-input)        [placeholder]
            └── Vet Summary Export  → VetSummaryExportScreen   (/pets/:petId/vet-summary-export) [placeholder]

TimelineScreen (/pets/:petId/timeline)
├── [FAB "+"]                  → TimelineEventFormScreen  (/pets/:petId/timeline/event-form)            (create)
└── [tap an event tile]        → TimelineEventFormScreen  (/pets/:petId/timeline/event-form?eventId=…)  (edit)
        └── save / cancel / delete → back to TimelineScreen

DocumentsScreen (/pets/:petId/documents)
├── [FAB "Add document"]       → DocumentFormScreen  (/pets/:petId/documents/form)               (create)
└── [tap a document tile]      → DocumentFormScreen  (/pets/:petId/documents/form?documentId=…)   (edit)
        └── save                → back to DocumentsScreen
```

## Screen-by-screen

### PetListScreen — home (`/`)
- **Add pet** → `PetFormRoute()` (create mode; `petId` query param is null).
- **Tap a pet** → `PetProfileRoute(petId:)`.

### PetFormScreen (`/pets/form`)
- Create (no `petId`) or edit (`?petId=…`). On successful save or cancel, returns to the previous screen (`context.router.back()`).

### PetProfileScreen (`/pets/:petId`)
- **Records card** links to the five pet-scoped feature screens, each with `petId`.
- **Delete** (AppBar) → confirmation dialog → on confirm, deletes and returns to the list.

### TimelineScreen (`/pets/:petId/timeline`)
- **FAB** → `TimelineEventFormRoute(petId:)` (create).
- **Tap event** → `TimelineEventFormRoute(petId:, eventId:)` (edit).

### TimelineEventFormScreen (`/pets/:petId/timeline/event-form`)
- Create/edit a health event; save, cancel, or delete returns to the timeline.

### DocumentsScreen (`/pets/:petId/documents`)
- **FAB "Add document"** → `DocumentFormRoute(petId:)` (create; picks a file and uploads on save).
- **Tap document** → `DocumentFormRoute(petId:, documentId:)` (edit; metadata only).

### DocumentFormScreen (`/pets/:petId/documents/form`)
- Create/edit a document; on save, pops back to the documents list.

### Reminders / Smart Input / Vet Summary Export
- Currently placeholder screens. They are reachable from the Records card but
  have no further navigation yet.

## How to verify the flows

The flows can be verified against a running app using the Dart/Flutter MCP
server (see `AGENTS.md` → MCP). Typical loop:

1. Run the app: `flutter run -d <device-id>`.
2. Connect the MCP server to the running app's DTD instance (the `dtd` tool:
   `listDtdUris` → `connect`).
3. Inspect the live UI with the `widget_inspector` (`get_widget_tree`,
   `summaryOnly: true`) to confirm the current screen and that the expected
   navigation widgets (FABs, tappable tiles, the Records card) are present.
4. After code changes, `hot_reload` and call `get_runtime_errors` to confirm no
   layout/exception regressions.

> Note: tap automation via `flutter_driver_command` requires the app to be
> launched with `enableFlutterDriverExtension()` (a dedicated driver
> entrypoint). Without it, verify by inspecting the widget tree and by manually
> tapping while watching `get_runtime_errors`.
