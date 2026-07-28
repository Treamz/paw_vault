import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/account/domain/entities/owner_profile.dart';
import 'package:paw_vault/features/account/domain/repositories/owner_profile_repository.dart';

/// In-memory [OwnerProfileRepository] for local-first mode.
class LocalOwnerProfileRepository implements OwnerProfileRepository {
  final _profiles = <String, OwnerProfile>{};

  @override
  Future<OwnerProfile?> getOwnerProfile(EntityId userId) async =>
      _profiles[userId.value];

  @override
  Future<void> saveOwnerProfile(EntityId userId, OwnerProfile profile) async {
    _profiles[userId.value] = profile;
  }
}
