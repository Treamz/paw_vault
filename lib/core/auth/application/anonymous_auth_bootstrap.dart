import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';

abstract final class AnonymousAuthBootstrap {
  static Future<AppUser> ensureSignedIn(AuthRepository authRepository) async {
    final currentUser = await authRepository.currentUser();
    if (currentUser != null) {
      return currentUser;
    }

    return authRepository.signInAnonymously();
  }
}
