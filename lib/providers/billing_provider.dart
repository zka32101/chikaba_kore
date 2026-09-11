import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/billing_service.dart';
import '../utils/logger.dart';
import 'auth_provider.dart';

final billingServiceProvider = Provider<BillingService>((ref) => BillingService());

/// 課金機能が利用可能か
final billingAvailableProvider = FutureProvider<bool>((ref) async {
  final billing = ref.watch(billingServiceProvider);
  return billing.init();
});

/// 利用可能なプロダクト一覧
final billingProductsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  final available = await ref.watch(billingAvailableProvider.future);
  if (!available) return [];
  final billing = ref.watch(billingServiceProvider);
  return billing.availableProducts;
});

/// 購入ストリーム監視
final billingPurchaseStreamProvider =
    StreamProvider<List<PurchaseDetails>>((ref) {
  final billing = ref.watch(billingServiceProvider);
  return billing.purchaseUpdates;
});

/// 購入処理（ローディング状態管理）
class BillingNotifier extends StateNotifier<AsyncValue<void>> {
  final BillingService _service;
  final Ref? _ref;

  BillingNotifier(this._service, [this._ref]) : super(const AsyncValue.data(null));

  /// プロダクトを購入
  Future<bool> purchaseProduct(ProductDetails product) async {
    state = const AsyncValue.loading();
    try {
      final success = await _service.purchaseProduct(product);
      state = const AsyncValue.data(null);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 購入完成
  Future<void> completePurchase(PurchaseDetails purchase) async {
    try {
      await _service.completePurchase(purchase);
      // 購入完了後、プレミアムステータスを更新
      if (_ref != null) {
        await _upgradeToPremium();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// プレミアムアップグレード
  Future<void> _upgradeToPremium() async {
    if (_ref == null) return;
    try {
      final authNotifier = _ref!.read(authNotifierProvider.notifier);
      await authNotifier.upgradeToPremium();
    } catch (e) {
      // ログに出力するのみ（購入自体は完了している）
      appLogger.w('Failed to update premium status: $e');
    }
  }

  /// 購入復元
  Future<void> restorePurchases() async {
    state = const AsyncValue.loading();
    try {
      await _service.restorePurchases();
      // 復元完了後、プレミアムステータスを更新
      if (_ref != null) {
        await _upgradeToPremium();
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final billingNotifierProvider =
    StateNotifierProvider<BillingNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(billingServiceProvider);
  return BillingNotifier(service, ref);
});

/// 購入更新を監視して自動で完成処理
final purchaseCompletionProvider = FutureProvider<void>((ref) async {
  final billingNotifier = ref.watch(billingNotifierProvider.notifier);
  final purchases = ref.watch(billingPurchaseStreamProvider);

  await purchases.when(
    data: (purchaseList) async {
      for (final purchase in purchaseList) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          // 購入完成処理
          await billingNotifier.completePurchase(purchase);
        }
      }
    },
    loading: () {},
    error: (error, stack) {},
  );
});
