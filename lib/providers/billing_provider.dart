import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/subscription_state.dart';
import '../purchases/purchases_bootstrap.dart';
import '../purchases/revenuecat_subscription_service.dart';
import '../services/subscription_service.dart';
import '../utils/logger.dart';
import 'auth_provider.dart';

/// main.dart で bootstrapPurchases() の結果を override する。
/// override が無い場合（テスト等）はデフォルトで利用不可扱い。
final purchasesAvailableProvider = Provider<bool>((ref) => false);

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final available = ref.watch(purchasesAvailableProvider);
  return available ? RevenueCatSubscriptionService() : LocalSubscriptionService();
});

/// 購入可能なプラン一覧（RevenueCat の Offerings）。ローカル実装時は空リスト。
final availablePackagesProvider = FutureProvider<List<Package>>((ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  if (service is! RevenueCatSubscriptionService) return [];
  return service.getAvailablePackages();
});

/// 現在のサブスクリプション状態
final subscriptionStatusProvider = FutureProvider<SubscriptionState>((ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getStatus();
});

/// 購入・復元処理（ローディング状態管理）
class SubscriptionNotifier extends StateNotifier<AsyncValue<void>> {
  final SubscriptionService _service;
  final Ref _ref;

  SubscriptionNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  /// プランを購入。Firestore の isPremium は RevenueCat Webhook
  /// (functions/src/revenuecatWebhook.ts) が非同期に更新するため、ここでは
  /// 購入操作のみ行い、完了後に currentUserProvider を再フェッチして反映を待つ。
  Future<bool> purchase(String productId) async {
    state = const AsyncValue.loading();
    try {
      await _service.purchasePremium(productId);
      await _refreshUserData();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      appLogger.e('Purchase error', error: e);
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> restorePurchases() async {
    state = const AsyncValue.loading();
    try {
      await _service.restorePurchases();
      await _refreshUserData();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      appLogger.e('Restore purchases error', error: e);
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> _refreshUserData() async {
    try {
      _ref.invalidate(currentUserProvider);
    } catch (e) {
      appLogger.w('Failed to refresh user data: $e');
    }
  }
}

final subscriptionNotifierProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return SubscriptionNotifier(service, ref);
});
