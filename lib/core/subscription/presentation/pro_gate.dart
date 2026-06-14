import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_events.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/subscription/domain/services/paywall_presenter.dart';
import 'package:paw_vault/core/subscription/presentation/cubit/subscription_cubit.dart';

/// The number of pets allowed on the free tier; beyond this requires Pro.
const int kFreePetLimit = 1;

/// Presents the RevenueCat-configured paywall and resolves to whether the user
/// has Pro afterwards.
///
/// Use to gate premium actions: call when the user lacks Pro, then proceed only
/// if the returned value is true.
Future<bool> showPaywall(BuildContext context) async {
  final presenter = context.read<PaywallPresenter>();
  final analytics = context.read<AnalyticsService>();

  analytics.logEvent(AnalyticsEvents.paywallViewed);
  final outcome = await presenter.presentIfNeeded();
  switch (outcome) {
    case PaywallOutcome.purchased:
      analytics.logEvent(AnalyticsEvents.purchaseCompleted);
    case PaywallOutcome.restored:
      analytics.logEvent(AnalyticsEvents.purchaseRestored);
    case PaywallOutcome.cancelled:
    case PaywallOutcome.notPresented:
    case PaywallOutcome.error:
      break;
  }

  if (!context.mounted) return false;
  return context.read<SubscriptionCubit>().isPro;
}
