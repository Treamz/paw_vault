import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/app/router/app_router.dart';
import 'package:paw_vault/core/auth/domain/repositories/account_auth_repository.dart';
import 'package:paw_vault/features/account/presentation/cubit/account_cubit.dart';

/// App-bar action showing the signed-in account state: opens the sign-in
/// screen for anonymous users, or an account sheet (email + sign out) for
/// signed-in users.
class AccountAction extends StatelessWidget {
  const AccountAction({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AccountCubit(context.read<AccountAuthRepository>()),
      child: const _AccountActionButton(),
    );
  }
}

class _AccountActionButton extends StatelessWidget {
  const _AccountActionButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(
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
    );
  }

  void _showAccountSheet(
    BuildContext context,
    AccountCubit cubit,
    AccountState state,
  ) {
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
            ],
          ),
        );
      },
    );
  }
}
