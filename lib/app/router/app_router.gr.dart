// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AccountScreen]
class AccountRoute extends PageRouteInfo<void> {
  const AccountRoute({List<PageRouteInfo>? children})
      : super(AccountRoute.name, initialChildren: children);

  static const String name = 'AccountRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AccountScreen();
    },
  );
}

/// generated route for
/// [DocumentExtractionScreen]
class DocumentExtractionRoute
    extends PageRouteInfo<DocumentExtractionRouteArgs> {
  DocumentExtractionRoute({
    required String petId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
          DocumentExtractionRoute.name,
          args: DocumentExtractionRouteArgs(petId: petId, key: key),
          rawPathParams: {'petId': petId},
          initialChildren: children,
        );

  static const String name = 'DocumentExtractionRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<DocumentExtractionRouteArgs>(
        orElse: () => DocumentExtractionRouteArgs(
          petId: pathParams.getString('petId'),
        ),
      );
      return DocumentExtractionScreen(petId: args.petId, key: args.key);
    },
  );
}

class DocumentExtractionRouteArgs {
  const DocumentExtractionRouteArgs({required this.petId, this.key});

  final String petId;

  final Key? key;

  @override
  String toString() {
    return 'DocumentExtractionRouteArgs{petId: $petId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DocumentExtractionRouteArgs) return false;
    return petId == other.petId && key == other.key;
  }

  @override
  int get hashCode => petId.hashCode ^ key.hashCode;
}

/// generated route for
/// [DocumentFormScreen]
class DocumentFormRoute extends PageRouteInfo<DocumentFormRouteArgs> {
  DocumentFormRoute({
    required String petId,
    String? documentId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
          DocumentFormRoute.name,
          args: DocumentFormRouteArgs(
            petId: petId,
            documentId: documentId,
            key: key,
          ),
          rawPathParams: {'petId': petId},
          rawQueryParams: {'documentId': documentId},
          initialChildren: children,
        );

  static const String name = 'DocumentFormRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<DocumentFormRouteArgs>(
        orElse: () => DocumentFormRouteArgs(
          petId: pathParams.getString('petId'),
          documentId: queryParams.optString('documentId'),
        ),
      );
      return DocumentFormScreen(
        petId: args.petId,
        documentId: args.documentId,
        key: args.key,
      );
    },
  );
}

class DocumentFormRouteArgs {
  const DocumentFormRouteArgs({required this.petId, this.documentId, this.key});

  final String petId;

  final String? documentId;

  final Key? key;

  @override
  String toString() {
    return 'DocumentFormRouteArgs{petId: $petId, documentId: $documentId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DocumentFormRouteArgs) return false;
    return petId == other.petId &&
        documentId == other.documentId &&
        key == other.key;
  }

  @override
  int get hashCode => petId.hashCode ^ documentId.hashCode ^ key.hashCode;
}

/// generated route for
/// [DocumentsScreen]
class DocumentsRoute extends PageRouteInfo<DocumentsRouteArgs> {
  DocumentsRoute({
    required String petId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
          DocumentsRoute.name,
          args: DocumentsRouteArgs(petId: petId, key: key),
          rawPathParams: {'petId': petId},
          initialChildren: children,
        );

  static const String name = 'DocumentsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<DocumentsRouteArgs>(
        orElse: () => DocumentsRouteArgs(petId: pathParams.getString('petId')),
      );
      return DocumentsScreen(petId: args.petId, key: args.key);
    },
  );
}

class DocumentsRouteArgs {
  const DocumentsRouteArgs({required this.petId, this.key});

  final String petId;

  final Key? key;

  @override
  String toString() {
    return 'DocumentsRouteArgs{petId: $petId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DocumentsRouteArgs) return false;
    return petId == other.petId && key == other.key;
  }

  @override
  int get hashCode => petId.hashCode ^ key.hashCode;
}

/// generated route for
/// [PetFormScreen]
class PetFormRoute extends PageRouteInfo<PetFormRouteArgs> {
  PetFormRoute({String? petId, Key? key, List<PageRouteInfo>? children})
      : super(
          PetFormRoute.name,
          args: PetFormRouteArgs(petId: petId, key: key),
          rawQueryParams: {'petId': petId},
          initialChildren: children,
        );

  static const String name = 'PetFormRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<PetFormRouteArgs>(
        orElse: () => PetFormRouteArgs(petId: queryParams.optString('petId')),
      );
      return PetFormScreen(petId: args.petId, key: args.key);
    },
  );
}

class PetFormRouteArgs {
  const PetFormRouteArgs({this.petId, this.key});

  final String? petId;

  final Key? key;

  @override
  String toString() {
    return 'PetFormRouteArgs{petId: $petId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PetFormRouteArgs) return false;
    return petId == other.petId && key == other.key;
  }

  @override
  int get hashCode => petId.hashCode ^ key.hashCode;
}

/// generated route for
/// [PetListScreen]
class PetListRoute extends PageRouteInfo<void> {
  const PetListRoute({List<PageRouteInfo>? children})
      : super(PetListRoute.name, initialChildren: children);

  static const String name = 'PetListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PetListScreen();
    },
  );
}

/// generated route for
/// [PetProfileScreen]
class PetProfileRoute extends PageRouteInfo<PetProfileRouteArgs> {
  PetProfileRoute({
    required String petId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
          PetProfileRoute.name,
          args: PetProfileRouteArgs(petId: petId, key: key),
          rawPathParams: {'petId': petId},
          initialChildren: children,
        );

  static const String name = 'PetProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<PetProfileRouteArgs>(
        orElse: () => PetProfileRouteArgs(petId: pathParams.getString('petId')),
      );
      return PetProfileScreen(petId: args.petId, key: args.key);
    },
  );
}

class PetProfileRouteArgs {
  const PetProfileRouteArgs({required this.petId, this.key});

  final String petId;

  final Key? key;

  @override
  String toString() {
    return 'PetProfileRouteArgs{petId: $petId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PetProfileRouteArgs) return false;
    return petId == other.petId && key == other.key;
  }

  @override
  int get hashCode => petId.hashCode ^ key.hashCode;
}

/// generated route for
/// [ReminderFormScreen]
class ReminderFormRoute extends PageRouteInfo<ReminderFormRouteArgs> {
  ReminderFormRoute({
    required String petId,
    String? reminderId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
          ReminderFormRoute.name,
          args: ReminderFormRouteArgs(
            petId: petId,
            reminderId: reminderId,
            key: key,
          ),
          rawPathParams: {'petId': petId},
          rawQueryParams: {'reminderId': reminderId},
          initialChildren: children,
        );

  static const String name = 'ReminderFormRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<ReminderFormRouteArgs>(
        orElse: () => ReminderFormRouteArgs(
          petId: pathParams.getString('petId'),
          reminderId: queryParams.optString('reminderId'),
        ),
      );
      return ReminderFormScreen(
        petId: args.petId,
        reminderId: args.reminderId,
        key: args.key,
      );
    },
  );
}

class ReminderFormRouteArgs {
  const ReminderFormRouteArgs({required this.petId, this.reminderId, this.key});

  final String petId;

  final String? reminderId;

  final Key? key;

  @override
  String toString() {
    return 'ReminderFormRouteArgs{petId: $petId, reminderId: $reminderId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReminderFormRouteArgs) return false;
    return petId == other.petId &&
        reminderId == other.reminderId &&
        key == other.key;
  }

  @override
  int get hashCode => petId.hashCode ^ reminderId.hashCode ^ key.hashCode;
}

/// generated route for
/// [RemindersScreen]
class RemindersRoute extends PageRouteInfo<RemindersRouteArgs> {
  RemindersRoute({
    required String petId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
          RemindersRoute.name,
          args: RemindersRouteArgs(petId: petId, key: key),
          rawPathParams: {'petId': petId},
          initialChildren: children,
        );

  static const String name = 'RemindersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<RemindersRouteArgs>(
        orElse: () => RemindersRouteArgs(petId: pathParams.getString('petId')),
      );
      return RemindersScreen(petId: args.petId, key: args.key);
    },
  );
}

class RemindersRouteArgs {
  const RemindersRouteArgs({required this.petId, this.key});

  final String petId;

  final Key? key;

  @override
  String toString() {
    return 'RemindersRouteArgs{petId: $petId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RemindersRouteArgs) return false;
    return petId == other.petId && key == other.key;
  }

  @override
  int get hashCode => petId.hashCode ^ key.hashCode;
}

/// generated route for
/// [SmartInputScreen]
class SmartInputRoute extends PageRouteInfo<SmartInputRouteArgs> {
  SmartInputRoute({
    required String petId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
          SmartInputRoute.name,
          args: SmartInputRouteArgs(petId: petId, key: key),
          rawPathParams: {'petId': petId},
          initialChildren: children,
        );

  static const String name = 'SmartInputRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<SmartInputRouteArgs>(
        orElse: () => SmartInputRouteArgs(petId: pathParams.getString('petId')),
      );
      return SmartInputScreen(petId: args.petId, key: args.key);
    },
  );
}

class SmartInputRouteArgs {
  const SmartInputRouteArgs({required this.petId, this.key});

  final String petId;

  final Key? key;

  @override
  String toString() {
    return 'SmartInputRouteArgs{petId: $petId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SmartInputRouteArgs) return false;
    return petId == other.petId && key == other.key;
  }

  @override
  int get hashCode => petId.hashCode ^ key.hashCode;
}

/// generated route for
/// [TimelineEventFormScreen]
class TimelineEventFormRoute extends PageRouteInfo<TimelineEventFormRouteArgs> {
  TimelineEventFormRoute({
    required String petId,
    String? eventId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
          TimelineEventFormRoute.name,
          args: TimelineEventFormRouteArgs(
            petId: petId,
            eventId: eventId,
            key: key,
          ),
          rawPathParams: {'petId': petId},
          rawQueryParams: {'eventId': eventId},
          initialChildren: children,
        );

  static const String name = 'TimelineEventFormRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<TimelineEventFormRouteArgs>(
        orElse: () => TimelineEventFormRouteArgs(
          petId: pathParams.getString('petId'),
          eventId: queryParams.optString('eventId'),
        ),
      );
      return TimelineEventFormScreen(
        petId: args.petId,
        eventId: args.eventId,
        key: args.key,
      );
    },
  );
}

class TimelineEventFormRouteArgs {
  const TimelineEventFormRouteArgs({
    required this.petId,
    this.eventId,
    this.key,
  });

  final String petId;

  final String? eventId;

  final Key? key;

  @override
  String toString() {
    return 'TimelineEventFormRouteArgs{petId: $petId, eventId: $eventId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TimelineEventFormRouteArgs) return false;
    return petId == other.petId && eventId == other.eventId && key == other.key;
  }

  @override
  int get hashCode => petId.hashCode ^ eventId.hashCode ^ key.hashCode;
}

/// generated route for
/// [TimelineScreen]
class TimelineRoute extends PageRouteInfo<TimelineRouteArgs> {
  TimelineRoute({
    required String petId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
          TimelineRoute.name,
          args: TimelineRouteArgs(petId: petId, key: key),
          rawPathParams: {'petId': petId},
          initialChildren: children,
        );

  static const String name = 'TimelineRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TimelineRouteArgs>(
        orElse: () => TimelineRouteArgs(petId: pathParams.getString('petId')),
      );
      return TimelineScreen(petId: args.petId, key: args.key);
    },
  );
}

class TimelineRouteArgs {
  const TimelineRouteArgs({required this.petId, this.key});

  final String petId;

  final Key? key;

  @override
  String toString() {
    return 'TimelineRouteArgs{petId: $petId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TimelineRouteArgs) return false;
    return petId == other.petId && key == other.key;
  }

  @override
  int get hashCode => petId.hashCode ^ key.hashCode;
}

/// generated route for
/// [VetSummaryExportScreen]
class VetSummaryExportRoute extends PageRouteInfo<VetSummaryExportRouteArgs> {
  VetSummaryExportRoute({
    required String petId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
          VetSummaryExportRoute.name,
          args: VetSummaryExportRouteArgs(petId: petId, key: key),
          rawPathParams: {'petId': petId},
          initialChildren: children,
        );

  static const String name = 'VetSummaryExportRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<VetSummaryExportRouteArgs>(
        orElse: () =>
            VetSummaryExportRouteArgs(petId: pathParams.getString('petId')),
      );
      return VetSummaryExportScreen(petId: args.petId, key: args.key);
    },
  );
}

class VetSummaryExportRouteArgs {
  const VetSummaryExportRouteArgs({required this.petId, this.key});

  final String petId;

  final Key? key;

  @override
  String toString() {
    return 'VetSummaryExportRouteArgs{petId: $petId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VetSummaryExportRouteArgs) return false;
    return petId == other.petId && key == other.key;
  }

  @override
  int get hashCode => petId.hashCode ^ key.hashCode;
}
