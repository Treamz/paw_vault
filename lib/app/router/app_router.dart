import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:paw_vault/features/account/presentation/screens/account_screen.dart';
import 'package:paw_vault/features/document_extraction/presentation/screens/document_extraction_screen.dart';
import 'package:paw_vault/features/documents/presentation/screens/document_form_screen.dart';
import 'package:paw_vault/features/documents/presentation/screens/documents_screen.dart';
import 'package:paw_vault/features/pets/presentation/screens/pet_form_screen.dart';
import 'package:paw_vault/features/pets/presentation/screens/pet_list_screen.dart';
import 'package:paw_vault/features/pets/presentation/screens/pet_profile_screen.dart';
import 'package:paw_vault/features/reminders/presentation/screens/reminder_form_screen.dart';
import 'package:paw_vault/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:paw_vault/features/smart_input/presentation/screens/smart_input_screen.dart';
import 'package:paw_vault/features/timeline/presentation/screens/timeline_event_form_screen.dart';
import 'package:paw_vault/features/timeline/presentation/screens/timeline_screen.dart';
import 'package:paw_vault/features/vet_summary_export/presentation/screens/vet_summary_export_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: PetListRoute.page, initial: true, path: '/'),
        AutoRoute(page: AccountRoute.page, path: '/account'),
        AutoRoute(page: PetFormRoute.page, path: '/pets/form'),
        AutoRoute(page: PetProfileRoute.page, path: '/pets/:petId'),
        AutoRoute(page: TimelineRoute.page, path: '/pets/:petId/timeline'),
        AutoRoute(
          page: TimelineEventFormRoute.page,
          path: '/pets/:petId/timeline/event-form',
        ),
        AutoRoute(page: DocumentsRoute.page, path: '/pets/:petId/documents'),
        AutoRoute(
          page: DocumentFormRoute.page,
          path: '/pets/:petId/documents/form',
        ),
        AutoRoute(
          page: DocumentExtractionRoute.page,
          path: '/pets/:petId/documents/scan',
        ),
        AutoRoute(page: RemindersRoute.page, path: '/pets/:petId/reminders'),
        AutoRoute(
          page: ReminderFormRoute.page,
          path: '/pets/:petId/reminders/form',
        ),
        AutoRoute(page: SmartInputRoute.page, path: '/pets/:petId/smart-input'),
        AutoRoute(
          page: VetSummaryExportRoute.page,
          path: '/pets/:petId/vet-summary-export',
        ),
      ];
}
