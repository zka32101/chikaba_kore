import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/subscription_state.dart';
import '../services/subscription_service.dart';

const _entitlementId = 'premium';

/// RevenueCat ラッパー。プレミアム会員（月額/年額）のオファリング取得・購入・復元・
/// 状態確認を行う。Firestore の `users/{uid}.isPremium` 更新は関与しない
/// （RevenueCat Webhook → Cloud Functions 経由でサーバー側が更新する。
/// `functions/src/revenuecatWebhook.ts` 参照）。
class RevenueCatSubscriptionService implements SubscriptionService {
  @override
  Future<SubscriptionState> getStatus() async {
    final info = await Purchases.getCustomerInfo();
    return _fromCustomerInfo(info);
  }

  /// 購入可能なオファリング一覧（月額/年額等のパッケージ）を取得する。
  Future<List<Package>> getAvailablePackages() async {
    final offerings = await Purchases.getOfferings();
    return offerings.current?.availablePackages ?? [];
  }

  @override
  Future<SubscriptionState> purchasePremium(String productId) async {
    final packages = await getAvailablePackages();
    final package = packages.firstWhere(
      (p) => p.storeProduct.identifier == productId,
      orElse: () => throw PurchaseException('指定されたプランが見つかりません: $productId'),
    );
    try {
      // 【要ローカル検証】purchases_flutterの`purchasePackage`戻り値の型はSDKバージョンによって
      // 異なる（v6以降は`CustomerInfo`を直接返すが、`{storeTransaction, customerInfo}`を返す
      // バージョンもある）。pubspec.yamlで固定したバージョンのAPIと一致するか、
      // `flutter pub get`後に必ず確認すること。
      final customerInfo = await Purchases.purchasePackage(package);
      return _fromCustomerInfo(customerInfo);
    } catch (e) {
      // PurchasesFlutterはユーザーによるキャンセル等をPlatformExceptionで通知する。
      // 詳細なエラーコード分岐（キャンセル/ネットワーク/決済拒否）は実接続確認後に詰める。
      throw PurchaseException('購入に失敗しました: $e');
    }
  }

  @override
  Future<SubscriptionState> restorePurchases() async {
    final info = await Purchases.restorePurchases();
    return _fromCustomerInfo(info);
  }

  SubscriptionState _fromCustomerInfo(CustomerInfo info) {
    final entitlement = info.entitlements.active[_entitlementId];
    if (entitlement == null) return SubscriptionState.free;
    final expiresAtStr = entitlement.expirationDate;
    return SubscriptionState(
      tier: SubscriptionTier.premium,
      expiresAt: expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null,
    );
  }
}
