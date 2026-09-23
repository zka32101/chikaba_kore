# デプロイメント準備チェックリスト

本番環境へのデプロイ前に以下のステップを実行してください。課金基盤は RevenueCat を使用します
（詳細: `docs/IN_APP_BILLING_GUIDE.md` / `docs/SECURITY_IMPLEMENTATION.md`）。

## 1. RevenueCat セットアップ

### 1.1 プロジェクト作成・ストア連携

1. [RevenueCat ダッシュボード](https://app.revenuecat.com) でプロジェクトを作成
2. App Store Connect / Google Play Console と連携
3. `premium` エンタイトルメントを作成し、月額・年額の Product を紐付ける

商品 ID:
- `com.yourwish.chikabamap.premium_monthly`（月額）
- `com.yourwish.chikabamap.premium_yearly`（年額）

### 1.2 APIキー取得

RevenueCat ダッシュボード → Project Settings → API Keys から
iOS/Android それぞれの Public API Key を取得する。

### 1.3 Webhook 設定

1. RevenueCat ダッシュボード → Project Settings → Integrations → Webhooks
2. URL に Cloud Functions のデプロイ先URL（`revenuecatWebhook`）を設定
3. Authorization header に秘密文字列を設定

## 2. Firebase 環境変数設定

```bash
firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET
```

1.3 で RevenueCat 側に設定した秘密文字列と同じ値を設定する。

## 3. Cloud Functions デプロイ

```bash
cd /home/user/chikaba_kore/functions
npm install
npm run build
firebase deploy --only functions
```

**確認:**
- Firebase コンソール → Functions で `revenuecatWebhook` / `onReviewCreate` の
  ステータスが「OK」
- ログにエラーが出ていないこと

## 4. Firestore セキュリティルール発行

```bash
cd /home/user/chikaba_kore
firebase deploy --only firestore:rules,firestore:indexes
```

**確認内容:**
- `isPremium` フィールドが Cloud Functions（`revenuecatWebhook`）のみで更新可能
- クライアントからの直接変更はブロックされている

## 5. iOS 側のセットアップ

### 5.1 App Store Connect で商品登録

1. App Store Connect → 「My Apps」 → 「近場まっぷ」
2. 「アプリ内課金」 → 「+」 から新規商品追加
3. 商品タイプ: 「自動更新購読」
4. 各商品の価格とローカライズ情報を設定（商品IDは RevenueCat 側の Product 定義と一致させる）

### 5.2 ビルド時の APIキー注入

```bash
flutter build ios --release \
  --dart-define=REVENUECAT_IOS_API_KEY=...
```

## 6. Android 側のセットアップ

### 6.1 Google Play Console で商品登録

1. Google Play Console → 「近場まっぷ」 → 「商品」
2. 「サブスクリプション」 → 「新しいサブスクリプション」
3. SKU ID と価格を設定（RevenueCat 側の Product 定義と一致させる）

### 6.2 ビルド時の APIキー注入

```bash
flutter build apk --release \
  --dart-define=REVENUECAT_ANDROID_API_KEY=...
```

## 7. テスト（本番デプロイ前）

### iOS Sandbox テスト

```bash
# 1. TestFlight でテストユーザー作成
#    App Store Connect → 「TestFlight」 → 「内部テスター」

# 2. iOS デバイスで Sandbox 環境をテスト
#    Settings → App Store → Sandbox Account でテストアカウントでログイン

# 3. アプリで購入テスト
#    購入ボタン → Sandbox 課金画面 → テスト認証情報で決済
```

### Android テストアカウント

```bash
# 1. Google Play Console で テストアカウント作成
#    「設定」 → 「ライセンス テスト」 → テストアカウント追加

# 2. テスト APK をテストデバイスにインストール
flutter build apk --release --dart-define=REVENUECAT_ANDROID_API_KEY=...

# 3. テストアカウントで Google アカウントにログイン

# 4. アプリで購入テスト
#    購入ボタン → Google Play Billing テスト決済
```

### RevenueCat Webhook テスト

RevenueCat ダッシュボードの Webhook 設定画面から「Send Test Event」を送信し、
Cloud Functions のログで正しく受信・処理できているか確認する。

## 8. 本番環境検証

### Cloud Firestore ログ監視

```bash
# iOS/Android でテスト購入後、以下を確認
firebase firestore --collection=users --document={userId}

# 以下のフィールドが更新されているか確認:
# - isPremium: true
# - premiumUpdatedAt: (タイムスタンプ)
# - premiumProduct: 商品 ID
```

### Cloud Functions ログ確認

```bash
firebase functions:log --only revenuecatWebhook

# 以下の情報が記録されているか確認:
# - Webhook 受信ログ（付与/剥奪）
# - Firestore 更新ログ
# - Authorization 検証失敗があれば401ログ
```

## 9. デプロイメント前の最終チェック

- [ ] RevenueCat プロジェクト作成・ストア連携済み
- [ ] `premium` エンタイトルメント・Product 設定済み
- [ ] RevenueCat Webhook Secret を Firebase Functions に設定
- [ ] Cloud Functions をデプロイ
- [ ] Firestore セキュリティルールをデプロイ
- [ ] iOS App Store Connect で商品登録
- [ ] Android Google Play Console で商品登録
- [ ] iOS Sandbox テスト完了
- [ ] Android テストアカウントテスト完了
- [ ] RevenueCat Webhook テストイベント送信・受信確認
- [ ] Firestore ログで isPremium 更新を確認
- [ ] クライアント（アプリ）側から isPremium を直接変更できないことを確認

## 10. 本番デプロイ実行

すべてのチェックが完了したら、以下を実行：

```bash
# 1. Firebase Functions を本番環境にデプロイ
firebase deploy --only functions

# 2. Firestore ルールを本番環境に発行
firebase deploy --only firestore:rules,firestore:indexes

# 3. 最新版のアプリをビルド・リリース
flutter build apk --release \
  --dart-define=REVENUECAT_ANDROID_API_KEY=...
flutter build ios --release \
  --dart-define=REVENUECAT_IOS_API_KEY=...

# 4. Google Play Store / App Store にアップロード
```

## 11. 本番環境でのモニタリング

### 定期監視項目

1. **購入成功率**
   ```firestore
   // 1時間ごとに確認
   - Firestore: isPremium が true に更新されたドキュメント数
   - premiumUpdatedAt の最新タイムスタンプ
   ```

2. **エラー検出**
   ```bash
   # 毎日確認
   firebase functions:log --only revenuecatWebhook | grep -i error
   ```

3. **RevenueCat ダッシュボードの分析画面**
   - MRR（月次経常収益）、チャーン率等を定期確認

## トラブルシューティング

### RevenueCat Webhook が届かない / isPremium が更新されない

```bash
# Functions ログを確認
firebase functions:log --only revenuecatWebhook
```

**確認事項:**
- Webhook URL がデプロイ先と一致しているか
- Authorization header の秘密文字列が一致しているか
- `linkPurchasesToUser` がログイン時に呼ばれているか（`app_user_id` が Firebase UID と一致しているか）

### Firestore 権限エラー

```
FirebaseError: Missing or insufficient permissions
```

→ `firestore.rules` がデプロイされているか確認

```bash
firebase deploy --only firestore:rules
```

### 商品が見つからない

```
Product not found in catalog
```

→ 商品 ID が RevenueCat / App Store Connect / Google Play Console で完全一致しているか確認

## 参考資料

- [RevenueCat Documentation](https://www.revenuecat.com/docs/getting-started)
- [RevenueCat Webhooks](https://www.revenuecat.com/docs/integrations/webhooks)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/start)
- [Cloud Functions for Firebase](https://firebase.google.com/docs/functions)
