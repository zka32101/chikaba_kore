import 'package:in_app_purchase/in_app_purchase.dart';
import '../utils/logger.dart';

class BillingService {
  static const String _premiumMonthlyId = 'com.yourwish.chikabamap.premium_monthly';
  static const String _premiumYearlyId = 'com.yourwish.chikabamap.premium_yearly';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  bool _available = false;
  List<ProductDetails> _products = [];

  /// 課金機能が利用可能か確認
  Future<bool> init() async {
    try {
      _available = await _inAppPurchase.isAvailable();
      appLogger.i('In-app purchase available: $_available');

      if (_available) {
        await _queryProducts();
      }
      return _available;
    } catch (e) {
      appLogger.e('Billing init error', error: e);
      return false;
    }
  }

  /// プロダクト情報を取得
  Future<void> _queryProducts() async {
    try {
      final Set<String> ids = <String>{_premiumMonthlyId, _premiumYearlyId};
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(ids);

      if (response.notFoundIDs.isNotEmpty) {
        appLogger.w('Not found products: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      appLogger.i('Loaded ${_products.length} products');
    } catch (e) {
      appLogger.e('Query products error', error: e);
    }
  }

  /// 利用可能なプロダクト取得
  List<ProductDetails> get availableProducts => _products;

  /// 月額プレミアム取得
  ProductDetails? get premiumMonthly => _products.firstWhere(
        (p) => p.id == _premiumMonthlyId,
        orElse: () => _products.isNotEmpty ? _products.first : null as ProductDetails,
      );

  /// 年間プレミアム取得
  ProductDetails? get premiumYearly => _products.firstWhere(
        (p) => p.id == _premiumYearlyId,
        orElse: () => _products.length > 1 ? _products[1] : null as ProductDetails,
      );

  /// 購入開始
  Future<bool> purchaseProduct(ProductDetails product) async {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      return true;
    } catch (e) {
      appLogger.e('Purchase error', error: e);
      return false;
    }
  }

  /// 購入完了を待つ
  Stream<List<PurchaseDetails>> get purchaseUpdates =>
      _inAppPurchase.purchaseStream;

  /// 保留中の購入を完成させる（iOS等で必要）
  Future<void> completePurchase(PurchaseDetails purchase) async {
    try {
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    } catch (e) {
      appLogger.e('Complete purchase error', error: e);
    }
  }

  /// 復元（別デバイスで購入した履歴を復元）
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      appLogger.i('Purchase restore requested');
    } catch (e) {
      appLogger.e('Restore purchases error', error: e);
    }
  }
}
