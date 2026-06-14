import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/app/router/app_router.dart';
import 'package:paw_vault/core/subscription/presentation/cubit/subscription_cubit.dart';

/// The number of pets allowed on the free tier; beyond this requires Pro.
const int kFreePetLimit = 1;

/// Opens the paywall and resolves to whether the user has Pro afterwards.
///
/// Use to gate premium actions: open the paywall when needed, then proceed only
/// if the returned value is true.
Future<bool> showPaywall(BuildContext context) async {
  await context.router.push(const PaywallRoute());
  if (!context.mounted) return false;
  return context.read<SubscriptionCubit>().isPro;
}
