# アプリ内課金実装ガイド

## 概要

このドキュメントでは、近場まっぷのアプリ内課金（In-App Purchasing）実装について説明します。

### 実装されている機能

- ✅ プレミアム商品（月額・年額）の定義
- ✅ 商品情報の取得
- ✅ 購入処理
- ✅ 購入完成処理（iOS対応）
- ✅ 購入復元（別デバイスでの購入履歴復元）
- ✅ プレミアムステータスの自動更新
- ✅ UI画面の実装

## ファイル構成

```
lib/
├── services/
│   └── billing_service.dart          # 課金機能サービス層
├── providers/
│   └── billing_provider.dart         # Riverpod状態管理
└── views/
    ├── screens/
    │   └── premium_screen.dart       # プレミアム購入画面
    └── widgets/
        └── premium_badge.dart        # ステータス表示ウィジェット
```

## 実装詳細

### 1. BillingService (lib/services/billing_service.dart)

In-App Purchase APIの直接的なラッパー。

**商品ID定義:**
```dart
static const String _premiumMonthlyId = 'com.yourwish.chikabamap.premium_monthly';
static const String _premiumYearlyId = 'com.yourwish.chikabamap.premium_yearly';
```

**主要メソッド:**

| メソッド | 説明 |
|---------|------|
| `init()` | 課金機能が利用可能か確認・初期化 |
| `_queryProducts()` | 商品情報をストアから取得 |
| `purchaseProduct(product)` | 購入開始 |
| `completePurchase(purchase)` | 購入完成（iOS等で必須） |
| `restorePurchases()` | 復元（別デバイスの購入履歴） |

### 2. BillingProvider (lib/providers/billing_provider.dart)

Riverpod経由のアプリ状態管理。

**主要プロバイダ:**

| プロバイダ | 型 | 説明 |
|----------|-----|------|
| `billingServiceProvider` | Provider | BillingServiceインスタンス |
| `billingAvailableProvider` | FutureProvider | 課金機能利用可否 |
| `billingProductsProvider` | FutureProvider | 商品一覧 |
| `billingPurchaseStreamProvider` | StreamProvider | 購入イベントストリーム |
| `billingNotifierProvider` | StateNotifierProvider | 購入操作・状態 |

**BillingNotifier:**
```dart
class BillingNotifier extends StateNotifier<AsyncValue<void>> {
  Future<bool> purchaseProduct(ProductDetails product)
  Future<void> completePurchase(PurchaseDetails purchase)
  Future<void> restorePurchases()
}
```

### 3. PremiumScreen (lib/views/screens/premium_screen.dart)

ユーザーがプレミアムを購入する画面。

**機能:**
- プレミアム会員特典の説明表示
- 月額・年額プランの表示
- 購入ボタン
- 以前の購入の復元ボタン

### 4. Premium Badge & Info Card (lib/views/widgets/premium_badge.dart)

**PremiumBadge:**
ユーザープロフィールなどに表示するプレミアム会員インジケーター

**PremiumInfoCard:**
ホーム画面などで使用するプレミアム情報カード

## 購入フロー

```
ユーザーが購入ボタンをクリック
         ↓
PremiumScreen._handlePurchase()
         ↓
BillingNotifier.purchaseProduct()
         ↓
BillingService.purchaseProduct() 
         ↓
InAppPurchase.buyNonConsumable() → ストアアプリへ
         ↓
（ユーザーがストアで確認・支払い）
         ↓
purchaseUpdates ストリーム → PurchaseStatus.purchased
         ↓
BillingNotifier.completePurchase()
         ↓
AuthNotifier.upgradeToPremium() → Firestore更新
         ↓
UserModel.isPremium = true ✅
```

## プレミアムステータスの自動更新

購入完了時、以下の流れで自動的にFirestoreが更新されます：

1. **BillingNotifier.completePurchase()** が呼ばれる
2. **_upgradeToPremium()** を実行
3. **AuthNotifier.upgradeToPremium()** を呼び出し
4. **AuthRepository** → **AuthService** → **Firestore** 更新
5. **currentUserProvider** が自動で再フェッチ

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

### プレミアム情報カードの表示

```dart
PremiumInfoCard(
  onUpgradePressed: () {
    context.push('/premium');
  },
)
```

## ストア設定

### iOS設定

1. App Store Connect にログイン
2. **マイアプリ** → **近場まっぷ** を選択
3. **App内課金** → **新規作成**
4. 以下の商品を作成：

| 商品ID | 名前 | 価格帯 |
|-------|------|--------|
| `com.yourwish.chikabamap.premium_monthly` | プレミアム月額 | $0.99 |
| `com.yourwish.chikabamap.premium_yearly` | プレミアム年額 | $9.99 |

### Android設定

1. Google Play Console にログイン
2. **近場まっぷ** → **商品** → **定期購入** を選択
3. 以下の商品を作成：

| SKU | 名前 | 価格帯 |
|-----|------|--------|
| `com.yourwish.chikabamap.premium_monthly` | プレミアム月額 | ¥99 |
| `com.yourwish.chikabamap.premium_yearly` | プレミアム年額 | ¥990 |

**注意:** 商品ID（SKU）は完全に一致している必要があります。

## テスト

### ローカルテスト

```bash
# テストビルド
flutter run --debug

# リリースビルド（実デバイス推奨）
flutter build apk --release
```

### テスト購入（Android）

Google Play Console のテストアカウントを設定：

1. **設定** → **ライセンステスト** → **ライセンステスター**
2. テスト用Googleアカウントを追加
3. テスト用APKでそのアカウントでサインイン
4. ストアから "テスト購入" が可能

### テスト購入（iOS）

Xcode でテスト用アカウント（Sandbox）を使用：

1. **Settings** → **Apps & Websites** → **Test User** 
2. テスト用Apple IDを作成
3. App Store で "テスト購入" が可能

## トラブルシューティング

### 商品が表示されない

- ✓ 商品IDが完全に一致しているか確認
- ✓ ストアで商品が承認されているか確認
- ✓ テスト用アカウントが設定されているか確認

### 購入できない

- ✓ テストアカウントでストアにサインインしているか
- ✓ デバイスにクレジットカードが登録されているか
- ✓ `BillingService.init()` が成功しているか

### 復元ボタンが機能しない

- ✓ `InAppPurchase.restorePurchases()` が正常に実行されているか
- ✓ Firestore の isPremium フィールドが更新されているか

## セキュリティ考慮事項

1. **購入検証**
   - 本番環境では、サーバー側で購入レシート検証を実装してください
   - クライアント側のフラグだけでは不十分です

2. **Firestore セキュリティルール**
   ```
   match /users/{userId} {
     allow read: if request.auth.uid == userId;
     allow update: if request.auth.uid == userId
       && !request.resource.data.isPremium  // クライアントから直接変更を防ぐ
   }
   ```

3. **ログ記録**
   - 購入イベントをサーバーログに記録
   - 不正な isPremium フラグの変更を検出

## 今後の改善

- [ ] サーバー側での購入レシート検証
- [ ] 複数の定期購入プランの管理
- [ ] キャンセル・払い戻し対応
- [ ] サブスクリプション設定画面
- [ ] 無料トライアル対応
- [ ] 分析・レポート機能

## 参考資料

- [In-App Purchase | Flutter](https://pub.dev/packages/in_app_purchase)
- [App Store: In-App Purchase](https://developer.apple.com/in-app-purchase/)
- [Google Play: In-App Billing](https://developer.android.com/google-play/billing)
