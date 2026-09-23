# アプリ内課金実装ガイド（RevenueCat）

## 概要

このドキュメントでは、近場まっぷのアプリ内課金（In-App Purchasing）実装について説明します。
課金基盤には **RevenueCat**（`purchases_flutter`）を使用しています
（姉妹アプリ「あんしんみち」(project-039) との統合を見据え、課金基盤を統一するため。
背景は `docs/INTEGRATION_PLAN_ANSHINMICHI.md` を参照）。

### 実装されている機能

- ✅ プレミアムプラン（月額・年額）のオファリング取得
- ✅ 購入処理
- ✅ 購入復元（別デバイスでの購入履歴復元）
- ✅ RevenueCat Webhook 経由でのプレミアムステータス自動更新
- ✅ UI画面の実装
- ✅ RevenueCat未接続環境（APIキー未設定）でのローカルフォールバック

## ファイル構成

```
lib/
├── models/
│   └── subscription_state.dart           # サブスクリプション状態モデル
├── services/
│   └── subscription_service.dart         # 抽象IF + ローカルフォールバック実装
├── purchases/
│   ├── purchases_bootstrap.dart          # RevenueCat SDK 初期化
│   └── revenuecat_subscription_service.dart  # RevenueCat実装
├── providers/
│   └── billing_provider.dart             # Riverpod状態管理
└── views/
    ├── screens/
    │   └── premium_screen.dart           # プレミアム購入画面
    └── widgets/
        └── premium_badge.dart            # ステータス表示ウィジェット

functions/src/
└── revenuecatWebhook.ts                  # RevenueCat Server Notifications 受信
```

## 実装詳細

### 1. SubscriptionService (lib/services/subscription_service.dart)

抽象インターフェース。RevenueCat未接続時は `LocalSubscriptionService`
（端末内フラグでの疑似購入、デモ用）にフォールバックする。

| メソッド | 説明 |
|---------|------|
| `getStatus()` | 現在のサブスクリプション状態を取得 |
| `purchasePremium(productId)` | 指定プランを購入 |
| `restorePurchases()` | 復元（別デバイスの購入履歴） |

### 2. RevenueCatSubscriptionService (lib/purchases/revenuecat_subscription_service.dart)

`purchases_flutter` のラッパー。`premium` エンタイトルメントの状態から
`SubscriptionState` を導出する。

### 3. purchases_bootstrap.dart

RevenueCat SDK を初期化する。`--dart-define=REVENUECAT_IOS_API_KEY=...` /
`REVENUECAT_ANDROID_API_KEY` が未設定の場合は `available: false` を返し、
自動的にローカル実装へフォールバックする。

`linkPurchasesToUser(uid)` は RevenueCat の `app_user_id` を Firebase Auth の
uid に一致させる（`Purchases.logIn(uid)`）。ログイン時（`auth_provider.dart`）
に呼ばれ、これにより RevenueCat Webhook が `app_user_id` をそのまま
`users/{uid}` のドキュメントIDとして使える。

### 4. billing_provider.dart

| プロバイダ | 型 | 説明 |
|----------|-----|------|
| `purchasesAvailableProvider` | Provider（main.dartでoverride） | RevenueCat利用可否 |
| `subscriptionServiceProvider` | Provider | RevenueCat or ローカル実装 |
| `availablePackagesProvider` | FutureProvider | 購入可能なプラン一覧 |
| `subscriptionStatusProvider` | FutureProvider | 現在のサブスクリプション状態 |
| `subscriptionNotifierProvider` | StateNotifierProvider | 購入・復元操作 |

### 5. PremiumScreen (lib/views/screens/premium_screen.dart)

ユーザーがプレミアムを購入する画面。

**機能:**
- プレミアム会員特典の説明表示
- 月額・年額プランの表示（RevenueCat Offerings から取得）
- 購入ボタン
- 以前の購入の復元ボタン

### 6. Premium Badge & Info Card (lib/views/widgets/premium_badge.dart)

`currentUserProvider`（Firestore の `users/{uid}.isPremium`）を参照するのみで、
RevenueCat には直接依存しない（Webhook が Firestore を更新するため）。

## 購入フロー

```
ユーザーが購入ボタンをクリック
         ↓
PremiumScreen._handlePurchase()
         ↓
SubscriptionNotifier.purchase(productId)
         ↓
RevenueCatSubscriptionService.purchasePremium()
         ↓
Purchases.purchasePackage() → ストアアプリへ
         ↓
（ユーザーがストアで確認・支払い）
         ↓
RevenueCat が購入を検知
         ↓
RevenueCat Webhook → Cloud Functions revenuecatWebhook
         ↓
Firestore users/{uid}.isPremium = true ✅
         ↓
currentUserProvider が Firestore の変更を検知して自動反映
```

## プレミアムステータスの自動更新

購入完了後、以下の流れで **サーバー側から** 自動的に Firestore が更新されます
（クライアントが直接 `isPremium` を書き込むことはない）：

1. RevenueCat が購入・更新・失効を検知
2. RevenueCat が設定された Webhook URL（`revenuecatWebhook`）にイベント通知
3. Cloud Functions が Authorization ヘッダーで正当性を検証
4. イベント種別に応じて Firestore の `isPremium` を更新
   - 付与: `INITIAL_PURCHASE` / `RENEWAL` / `UNCANCELLATION` / `PRODUCT_CHANGE`
   - 剥奪: `EXPIRATION`
5. クライアント側は `currentUserProvider`（Firestore監視）経由で自動反映

## 使用例

### プレミアム画面への遷移

```dart
context.push('/premium');
```

### プレミアムステータスの確認

```dart
final currentUser = ref.watch(currentUserProvider);
bool isPremium = currentUser.value?.isPremium ?? false;
```

### プレミアムバッジの表示

```dart
PremiumBadge()  // デフォルトサイズ
PremiumBadge(size: 24, color: Colors.amber.shade400)
```

## 設定手順

### 1. RevenueCat プロジェクト作成

1. [RevenueCat ダッシュボード](https://app.revenuecat.com) でプロジェクトを作成
2. App Store Connect / Google Play Console と連携
3. `premium` エンタイトルメントを作成し、月額・年額の Product を紐付ける

商品ID:
| 商品ID | 用途 |
|-------|------|
| `com.yourwish.chikabamap.premium_monthly` | プレミアム月額 |
| `com.yourwish.chikabamap.premium_yearly` | プレミアム年額 |

### 2. APIキーの注入

```bash
flutter build apk --release \
  --dart-define=REVENUECAT_IOS_API_KEY=... \
  --dart-define=REVENUECAT_ANDROID_API_KEY=...
```

### 3. Webhook 設定

1. RevenueCat ダッシュボード → Project Settings → Integrations → Webhooks
2. URL に Cloud Functions のデプロイ先URL（`revenuecatWebhook`）を設定
3. Authorization header に秘密文字列を設定
4. 同じ値を Cloud Functions の環境変数 `REVENUECAT_WEBHOOK_SECRET` に設定

```bash
firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET
```

## ストア設定

### iOS設定

1. App Store Connect にログイン
2. **マイアプリ** → **近場まっぷ** を選択
3. **App内課金** → **新規作成**
4. 商品ID・価格帯を RevenueCat ダッシュボードの Product 定義と一致させる

### Android設定

1. Google Play Console にログイン
2. **近場まっぷ** → **商品** → **定期購入** を選択
3. 商品ID（SKU）を RevenueCat ダッシュボードの Product 定義と一致させる

**注意:** 商品ID（SKU）は完全に一致している必要があります。

## テスト

### テスト購入（Android）

Google Play Console のテストアカウントを設定：

1. **設定** → **ライセンステスト** → **ライセンステスター**
2. テスト用Googleアカウントを追加
3. テスト用APKでそのアカウントでサインイン

### テスト購入（iOS）

Xcode でテスト用アカウント（Sandbox）を使用。

## トラブルシューティング

### 商品が表示されない

- ✓ RevenueCat ダッシュボードで Offering に Package が紐付いているか確認
- ✓ ストアで商品が承認されているか確認
- ✓ APIキーが正しく注入されているか（`--dart-define`）確認

### 購入できても isPremium が更新されない

- ✓ Webhook の Authorization header 設定が一致しているか
- ✓ `REVENUECAT_WEBHOOK_SECRET` が Cloud Functions に設定されているか
- ✓ Cloud Functions のログでイベントを受信できているか確認
- ✓ RevenueCat の `app_user_id` が Firebase Auth の `uid` と一致しているか
  （`linkPurchasesToUser` がログイン時に呼ばれているか確認）

## セキュリティ考慮事項

1. **購入検証はサーバー側（RevenueCat + Webhook）で実施**
   - クライアント側から `isPremium` を直接更新することはできない
     （`firestore.rules` で Cloud Functions 経由の更新のみ許可）
2. **Webhook の認証**
   - Authorization header の秘密文字列で検証（一致しなければ401を返す）
3. **ログ記録**
   - `revenuecatWebhook` は付与・剥奪の両方を Cloud Functions ログに記録

## 今後の改善

- [ ] サブスクリプション設定画面（プラン変更・解約導線）
- [ ] 無料トライアル対応
- [ ] 分析・レポート機能

## 参考資料

- [RevenueCat Documentation](https://www.revenuecat.com/docs/getting-started)
- [purchases_flutter | pub.dev](https://pub.dev/packages/purchases_flutter)
- [RevenueCat Webhooks](https://www.revenuecat.com/docs/integrations/webhooks)
