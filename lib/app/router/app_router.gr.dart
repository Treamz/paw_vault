// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

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
        rawPathParams: {'petId': petId},
        initialChildren: children,
      );

  static const String name = 'PetFormRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<PetFormRouteArgs>(
        orElse: () => PetFormRouteArgs(petId: pathParams.optString('petId')),
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
         rawPathParams: {'petId': petId, 'eventId': eventId},
         initialChildren: children,
       );

  static const String name = 'TimelineEventFormRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TimelineEventFormRouteArgs>(
        orElse:
            () => TimelineEventFormRouteArgs(
              petId: pathParams.getString('petId'),
              eventId: pathParams.optString('eventId'),
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
        orElse:
            () =>
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
