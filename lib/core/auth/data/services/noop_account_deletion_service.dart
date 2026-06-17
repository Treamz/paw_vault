import 'package:paw_vault/core/auth/domain/services/account_deletion_service.dart';

/// No-op deletion used in local-first mode, where there is no remote account or
/// data to remove.
class NoopAccountDeletionService implements AccountDeletionService {
  const NoopAccountDeletionService();

  @override
  Future<void> deleteAccount() async {}
}
