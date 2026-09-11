# デプロイメント準備チェックリスト

すべての実装フェーズが完了しました。本番環境へのデプロイ前に以下のステップを実行してください。

## 1. Firebase 環境変数設定 ✅

### Apple App Store Secret

```bash
firebase functions:config:set apple.app_secret="YOUR_SHARED_SECRET"
```

**取得方法:**
1. [App Store Connect](https://appstoreconnect.apple.com) にログイン
2. 「My Apps」 → 「近場まっぷ」 → 「アプリ内課金」
3. 「Shared Secret」をコピー

### Google Play Service Account

```bash
# service-account.json を Base64 エンコード
firebase functions:config:set google.service_account="$(cat /path/to/service-account.json | jq -c .)"
```

**取得方法:**
1. [Google Play Console](https://play.google.com/console) にアクセス
2. 「設定」 → 「API とアクセス」 → 「サービスアカウント」
3. JSON ファイルをダウンロード
4. サービスアカウントに以下の権限を確認：
   - Android Publisher API: アクセス可能
   - `androidpublisher` スコープ

## 2. Cloud Functions デプロイ

```bash
# 関数をデプロイ
cd /home/user/chikaba_kore/functions
npm install
firebase deploy --only functions:verifyPurchaseReceipt
```

**確認:**
- Firebase コンソール → Functions でステータスが「OK」
- ログに `verifyPurchaseReceipt` が表示される

## 3. Firestore セキュリティルール発行

```bash
cd /home/user/chikaba_kore
firebase deploy --only firestore:rules
```

**確認内容:**
- `isPremium` フィールドが Cloud Functions のみで更新可能
- クライアントからの直接変更はブロックされている

```firestore
// firestore.rules 内の検証ルール
function isValidUserUpdate(oldData, newData) {
  let isPremiumUnchanged = (('isPremium' in oldData) && (newData.isPremium == oldData.isPremium))
    || (!('isPremium' in oldData) && !('isPremium' in newData));
  
  return isPremiumUnchanged && isValidUserCreate(newData);
}
```

## 4. iOS 側のセットアップ

### 4.1 App Store Connect で商品登録

商品 ID:
- `com.yourwish.chikabamap.premium_monthly` (月額 ¥600)
- `com.yourwish.chikabamap.premium_yearly` (年額 ¥5,900)

**ステップ:**
1. App Store Connect → 「My Apps」 → 「近場まっぷ」
2. 「アプリ内課金」 → 「+」 から新規商品追加
3. 商品タイプ: 「自動更新購読」
4. 各商品の価格とローカライズ情報を設定
5. 「同意と同意」で確認

### 4.2 Shared Secret 設定確認

```bash
# Functions の環境変数に設定済みか確認
firebase functions:config:get apple.app_secret
```

## 5. Android 側のセットアップ

### 5.1 Google Play Console で商品登録

SKU ID（商品 ID と同じ）:
- `com.yourwish.chikabamap.premium_monthly`
- `com.yourwish.chikabamap.premium_yearly`

**ステップ:**
1. Google Play Console → 「近場まっぷ」 → 「商品」
2. 「サブスクリプション」 → 「新しいサブスクリプション」
3. SKU ID と価格を設定
4. 各言語で説明を追加

### 5.2 サービスアカウント権限確認

```bash
# Functions 環境から確認
firebase functions:config:get google.service_account
```

**必要な権限:**
- Google Play 管理 API: 有効
- Android Publisher API へのアクセス

## 6. テスト（本番デプロイ前）

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
flutter build apk --release

# 3. テストアカウントで Google アカウントにログイン

# 4. アプリで購入テスト
#    購入ボタン → Google Play Billing テスト決済
```

## 7. 本番環境検証

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
firebase functions:log --only verifyPurchaseReceipt

# 以下の情報が記録されているか確認:
# - Receipt 検証成功ログ
# - Firestore 更新ログ
# - エラーログ（失敗した場合）
```

## 8. デプロイメント前の最終チェック

- [ ] Apple App Secret を Firebase に設定
- [ ] Google Play Service Account を Firebase に設定
- [ ] Cloud Functions をデプロイ
- [ ] Firestore セキュリティルールをデプロイ
- [ ] iOS App Store Connect で商品登録
- [ ] Android Google Play Console で商品登録
- [ ] iOS Sandbox テスト完了
- [ ] Android テストアカウントテスト完了
- [ ] Firestore ログで isPremium 更新を確認
- [ ] Cloud Functions ログにエラーが無いか確認
- [ ] クライアント（アプリ）側から isPremium を直接変更できないことを確認

## 9. 本番デプロイ実行

すべてのチェックが完了したら、以下を実行：

```bash
# 1. Firebase Functions を本番環境にデプロイ
firebase deploy --only functions:verifyPurchaseReceipt

# 2. Firestore ルールを本番環境に発行
firebase deploy --only firestore:rules

# 3. 最新版のアプリをビルド・リリース
flutter build apk --release    # Android
flutter build ios --release    # iOS（macOS のみ）

# 4. Google Play Store / App Store にアップロード
```

## 10. 本番環境でのモニタリング

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
   firebase functions:log --only verifyPurchaseReceipt | grep -i error
   ```

3. **不正検出**
   - 同一ユーザーの短時間での複数購入
   - Receipt 検証失敗が多発
   - premiumProduct と実際の購入 SKU の不一致

### アラート設定（推奨）

```bash
# Cloud Functions で例外発生時にログ
console.error(`Purchase verification failed: ${error.message}`);

# Firestore Analytics で isPremium 変更を監視
```

## トラブルシューティング

### Receipt 検証が失敗する

**原因の特定:**
1. iOS: Sandbox vs Production 環境の混在
2. Android: Service Account の権限不足

**解決:**
```bash
# Functions 設定を確認
firebase functions:config:get

# ログで詳細エラーを確認
firebase functions:log --only verifyPurchaseReceipt
```

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

→ 商品 ID が App Store Connect / Google Play Console と完全一致しているか確認

## 参考資料

- [App Store Server Notifications](https://developer.apple.com/documentation/app-store-server-notifications)
- [Google Play Billing Documentation](https://developer.android.com/google-play/billing)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/start)
- [Cloud Functions for Firebase](https://firebase.google.com/docs/functions)
