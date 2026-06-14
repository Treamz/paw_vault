import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/subscription/domain/entities/subscription_package.dart';
import 'package:paw_vault/core/subscription/domain/services/subscription_service.dart';
import 'package:paw_vault/features/paywall/presentation/cubit/paywall_cubit.dart';

@RoutePage()
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static const _features = [
    'Unlimited pets',
    'Smart Input — turn notes into entries with AI',
    'AI document scanning',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PaywallCubit(
        subscriptionService: context.read<SubscriptionService>(),
        analytics: context.read<AnalyticsService>(),
      )..load(),
      child: const _PaywallView(),
    );
  }
}

class _PaywallView extends StatelessWidget {
  const _PaywallView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaywallCubit, PaywallState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == PaywallStatus.purchased) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome to PawVault Pro!')),
          );
          context.router.maybePop(true);
        } else if (state.status == PaywallStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PawVault Pro'),
          actions: [
            BlocBuilder<PaywallCubit, PaywallState>(
              builder: (context, state) => TextButton(
                onPressed: state.isBusy
                    ? null
                    : () => context.read<PaywallCubit>().restore(),
                child: const Text('Restore'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<PaywallCubit, PaywallState>(
            builder: (context, state) {
              return switch (state.status) {
                PaywallStatus.loading => const Center(
                    child: CircularProgressIndicator(),
                  ),
                PaywallStatus.failure when state.packages.isEmpty =>
                  _UnavailableView(
                    message: state.errorMessage ??
                        'Subscriptions are unavailable right now.',
                    onRetry: () => context.read<PaywallCubit>().load(),
                  ),
                _ => _Offer(state: state),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _Offer extends StatelessWidget {
  const _Offer({required this.state});

  final PaywallState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          Icons.workspace_premium,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Unlock everything PawVault offers',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        for (final feature in PaywallScreen._features)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(feature, style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        for (final package in state.packages)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PackageButton(
              package: package,
              busy: state.isBusy,
              onTap: () => context.read<PaywallCubit>().purchase(package),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Subscription renews automatically until cancelled. Manage or cancel '
          'anytime in your App Store settings.',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PackageButton extends StatelessWidget {
  const _PackageButton({
    required this.package,
    required this.busy,
    required this.onTap,
  });

  final SubscriptionPackage package;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = package.hasFreeTrial && package.trialDescription != null
        ? 'Start ${package.trialDescription} — then ${package.priceString}/'
            '${package.period}'
        : '${package.priceString} / ${package.period}';
    return FilledButton(
      onPressed: busy ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
