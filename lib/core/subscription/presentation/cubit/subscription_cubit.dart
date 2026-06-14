import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/subscription/domain/entities/entitlements.dart';
import 'package:paw_vault/core/subscription/domain/services/subscription_service.dart';

/// App-level cubit exposing the current entitlement state so gating widgets can
/// react to it. Provided once near the root of the widget tree.
class SubscriptionCubit extends Cubit<Entitlements> {
  SubscriptionCubit(this._service) : super(Entitlements.free) {
    _subscription = _service.watchEntitlements().listen(emit);
  }

  final SubscriptionService _service;
  StreamSubscription<Entitlements>? _subscription;

  bool get isPro => state.isPro;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
