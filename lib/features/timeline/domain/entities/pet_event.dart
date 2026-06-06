import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';

enum PetEventType {
  vaccination,
  vetVisit,
  medication,
  labTest,
  surgery,
  symptom,
  grooming,
  food,
  allergy,
  documentAdded,
  other,
}

enum PetEventSource {
  manual,
  smartText,
  documentScan,
  imported,
}

class PetEvent {
  const PetEvent({
    required this.id,
    required this.userId,
    required this.petId,
    required this.type,
    required this.title,
    required this.date,
    required this.source,
    this.description,
    this.nextReminderDate,
    this.attachments = const [],
    this.createdAt,
    this.updatedAt,
  });

  final EntityId id;
  final EntityId userId;
  final EntityId petId;
  final PetEventType type;
  final String title;
  final String? description;
  final UtcDateTime date;
  final UtcDateTime? nextReminderDate;
  final List<Uri> attachments;
  final PetEventSource source;
  final UtcDateTime? createdAt;
  final UtcDateTime? updatedAt;
}
