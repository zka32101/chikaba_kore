import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/billing_service.dart';
import '../services/receipt_verification_service.dart';
import '../utils/logger.dart';
import 'auth_provider.dart';

final billingServiceProvider = Provider<BillingService>((ref) => BillingService());

final receiptVerificationProvider = Provider<ReceiptVerificationService>(
  (ref) => ReceiptVerificationService(),
);

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
  final ReceiptVerificationService _verificationService;
  final Ref? _ref;

  BillingNotifier(
    this._service,
    this._verificationService, [
    this._ref,
  ]) : super(const AsyncValue.data(null));

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

  /// 購入完成（レシート検証付き）
  Future<void> completePurchase(PurchaseDetails purchase) async {
    try {
      // サーバー側でレシートを検証
      final verified = await _verificationService.verifyPurchaseAndUpdatePremium(
        purchase,
      );

      if (!verified) {
        appLogger.w('Purchase verification failed: ${purchase.productID}');
        throw Exception('Purchase verification failed');
      }

      // 検証成功後、ネイティブ側で購入完成処理
      await _service.completePurchase(purchase);

      // プレミアムステータスは既にサーバー側で更新されている
      // ローカルのキャッシュを更新
      if (_ref != null) {
        await _refreshUserData();
      }
    } catch (e) {
      appLogger.e('Complete purchase error', error: e);
      rethrow;
    }
  }

  /// ユーザーデータを更新（サーバー側で既にプレミアム更新済み）
  Future<void> _refreshUserData() async {
    if (_ref == null) return;
    try {
      // currentUserProvider を無効化して再フェッチ
      _ref!.refresh(currentUserProvider);
      appLogger.i('User data refreshed');
    } catch (e) {
      appLogger.w('Failed to refresh user data: $e');
    }
  }

  /// 購入復元
  Future<void> restorePurchases() async {
    state = const AsyncValue.loading();
    try {
      await _service.restorePurchases();
      // 復元完了後、ユーザーデータを更新
      if (_ref != null) {
        await _refreshUserData();
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
  final verificationService = ref.watch(receiptVerificationProvider);
  return BillingNotifier(service, verificationService, ref);
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
