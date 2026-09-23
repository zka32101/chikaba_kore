import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat SDK の初期化。
///
/// 【設定手順】
///   1. RevenueCat ダッシュボードでプロジェクトを作成し、App Store Connect/Google Play Console
///      と連携する
///   2. 「premium」エンタイトルメントと、月額/年額それぞれの Product を設定する
///      （`revenuecat_subscription_service.dart` の `_entitlementId` 参照）
///   3. iOS/Android それぞれの Public API Key を取得し、`--dart-define=REVENUECAT_IOS_API_KEY=...`
///      等で注入する（プレースホルダーのままコミットしないこと）
///   4. RevenueCat ダッシュボードの Webhooks 設定で Cloud Functions の
///      `revenuecatWebhook` エンドポイントを登録し、Authorization ヘッダーに
///      設定する秘密文字列を Firebase Functions の環境変数 `revenuecat.webhook_secret`
///      に設定する（`functions/src/revenuecatWebhook.ts` 参照）
///
/// 未設定・初期化失敗時は `available = false` を返し、`LocalSubscriptionService`
/// （デモ用フラグでの疑似購入）へフォールバックする。
class PurchasesBootstrapResult {
  const PurchasesBootstrapResult({required this.available, this.error});
  final bool available;
  final Object? error;
}

const _iosApiKey = String.fromEnvironment('REVENUECAT_IOS_API_KEY');
const _androidApiKey = String.fromEnvironment('REVENUECAT_ANDROID_API_KEY');

Future<PurchasesBootstrapResult> bootstrapPurchases() async {
  final apiKey =
      defaultTargetPlatform == TargetPlatform.iOS ? _iosApiKey : _androidApiKey;
  if (apiKey.isEmpty) {
    debugPrint('[PurchasesBootstrap] RevenueCat APIキー未設定のためローカル実装にフォールバックします');
    return const PurchasesBootstrapResult(available: false);
  }

  try {
    await Purchases.setLogLevel(LogLevel.warn);
    await Purchases.configure(PurchasesConfiguration(apiKey));
    return const PurchasesBootstrapResult(available: true);
  } catch (error) {
    debugPrint('[PurchasesBootstrap] RevenueCat初期化に失敗したためローカル実装にフォールバックします: $error');
    return PurchasesBootstrapResult(available: false, error: error);
  }
}

/// RevenueCat の app_user_id を Firebase Auth の uid に一致させる。
/// Webhook 側 (functions/src/revenuecatWebhook.ts) が app_user_id をそのまま
/// Firestore の users/{uid} ドキュメントIDとして使えるようにするため。
Future<void> linkPurchasesToUser(String uid) async {
  try {
    await Purchases.logIn(uid);
  } catch (error) {
    debugPrint('[PurchasesBootstrap] Purchases.logIn失敗: $error');
  }
}
