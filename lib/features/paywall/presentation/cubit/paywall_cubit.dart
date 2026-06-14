import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/analytics/data/services/noop_analytics_service.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_events.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/subscription/domain/entities/subscription_package.dart';
import 'package:paw_vault/core/subscription/domain/services/subscription_service.dart';

enum PaywallStatus { loading, ready, purchasing, restoring, purchased, failure }

class PaywallState {
  const PaywallState({
    this.status = PaywallStatus.loading,
    this.packages = const [],
    this.errorMessage,
  });

  final PaywallStatus status;
  final List<SubscriptionPackage> packages;
  final String? errorMessage;

  bool get isBusy =>
      status == PaywallStatus.purchasing || status == PaywallStatus.restoring;

  PaywallState copyWith({
    PaywallStatus? status,
    List<SubscriptionPackage>? packages,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PaywallState(
      status: status ?? this.status,
      packages: packages ?? this.packages,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PaywallCubit extends Cubit<PaywallState> {
  PaywallCubit({
    required SubscriptionService subscriptionService,
    AnalyticsService? analytics,
  })  : _subscriptionService = subscriptionService,
        _analytics = analytics ?? const NoopAnalyticsService(),
        super(const PaywallState());

  final SubscriptionService _subscriptionService;
  final AnalyticsService _analytics;

  Future<void> load() async {
    emit(state.copyWith(status: PaywallStatus.loading, clearError: true));
    _analytics.logEvent(AnalyticsEvents.paywallViewed);
    try {
      final packages = await _subscriptionService.offerings();
      emit(state.copyWith(status: PaywallStatus.ready, packages: packages));
    } catch (error) {
      emit(
        state.copyWith(
          status: PaywallStatus.failure,
          errorMessage: 'Could not load subscription options.',
        ),
      );
    }
  }

  Future<void> purchase(SubscriptionPackage package) async {
    emit(state.copyWith(status: PaywallStatus.purchasing, clearError: true));
    try {
      final entitlements = await _subscriptionService.purchase(package);
      if (entitlements.isPro) {
        _analytics.logEvent(
          AnalyticsEvents.purchaseCompleted,
          parameters: {AnalyticsParams.product: package.id},
        );
        emit(state.copyWith(status: PaywallStatus.purchased));
      } else {
        emit(state.copyWith(status: PaywallStatus.ready));
      }
    } on PurchaseCancelledException {
      emit(state.copyWith(status: PaywallStatus.ready));
    } on PurchaseException catch (error) {
      emit(
        state.copyWith(
          status: PaywallStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }

  Future<void> restore() async {
    emit(state.copyWith(status: PaywallStatus.restoring, clearError: true));
    try {
      final entitlements = await _subscriptionService.restore();
      if (entitlements.isPro) {
        _analytics.logEvent(AnalyticsEvents.purchaseRestored);
        emit(state.copyWith(status: PaywallStatus.purchased));
      } else {
        emit(
          state.copyWith(
            status: PaywallStatus.failure,
            errorMessage: 'No previous purchases found to restore.',
          ),
        );
      }
    } on PurchaseException catch (error) {
      emit(
        state.copyWith(
          status: PaywallStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }
}
