import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/app/router/app_router.dart';
import 'package:paw_vault/core/auth/domain/repositories/account_auth_repository.dart';
import 'package:paw_vault/core/auth/domain/services/account_deletion_service.dart';
import 'package:paw_vault/features/account/presentation/cubit/account_cubit.dart';

/// App-bar action showing the signed-in account state: opens the sign-in
/// screen for anonymous users, or an account sheet (email, sign out, delete
/// account) for signed-in users.
class AccountAction extends StatelessWidget {
  const AccountAction({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AccountCubit(
        context.read<AccountAuthRepository>(),
        accountDeletionService: context.read<AccountDeletionService>(),
      ),
      child: const _AccountActionButton(),
    );
  }
}

class _AccountActionButton extends StatelessWidget {
  const _AccountActionButton();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountCubit, AccountState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == AccountStatus.failure &&
          current.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage!)),
        );
      },
      child: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, state) {
          final signedIn = state.isSignedIn;
          return IconButton(
            icon: Icon(
              signedIn ? Icons.account_circle : Icons.account_circle_outlined,
            ),
            tooltip: signedIn ? 'Account' : 'Sign in',
            onPressed: () {
              if (signedIn) {
                _showAccountSheet(context, context.read<AccountCubit>(), state);
              } else {
                context.router.push(const AccountRoute());
              }
            },
          );
        },
      ),
    );
  }

  void _showAccountSheet(
    BuildContext context,
    AccountCubit cubit,
    AccountState state,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: Text(state.user?.email ?? 'Signed in'),
                subtitle: const Text('Your records sync to this account'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () {
                  cubit.signOut();
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_forever,
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
                title: Text(
                  'Delete account',
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.error,
                  ),
                ),
                subtitle: const Text('Permanently removes your account & data'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmAndDelete(context, cubit, messenger);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    AccountCubit cubit,
    ScaffoldMessengerState messenger,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: const Text(
            'This permanently deletes your account and all pets, documents, '
            'reminders, and other records you have saved. This cannot be '
            'undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await cubit.deleteAccount();

    // A failure surfaces via the BlocListener above; only confirm success here.
    if (cubit.state.status != AccountStatus.failure) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Your account and data were deleted.')),
      );
    }
  }
}
