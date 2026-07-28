import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/account/domain/entities/owner_profile.dart';

/// Stores the owner's own contact details (name/phone) per user account.
abstract interface class OwnerProfileRepository {
  Future<OwnerProfile?> getOwnerProfile(EntityId userId);

  Future<void> saveOwnerProfile(EntityId userId, OwnerProfile profile);
}
