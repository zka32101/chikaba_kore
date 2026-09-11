# セキュリティ実装ガイド

## 概要

アプリ内課金機能のセキュリティを強化するための実装ガイドです。

## 実装されたセキュリティ対策

### 1. サーバー側でのレシート検証 ✅

**ファイル:** `lib/services/receipt_verification_service.dart`

- iOS: App Store Connect API でレシート検証
- Android: Google Play Billing API でレシート検証
- Cloud Functions で検証実施

**利点:**
- クライアント側での改ざんを防止
- App Store/Google Play の公式APIで検証
- 検証失敗時はプレミアムフラグを更新しない

### 2. Cloud Functions による検証 ✅

**ファイル:** `functions/src/verifyPurchaseReceipt.ts`

```typescript
// 購入レシートをサーバー側で検証
export const verifyPurchaseReceipt = functions.https.onCall(
  async (data, context) => {
    // 1. ユーザー認証確認
    // 2. レシート検証（Apple/Google）
    // 3. Firestore の isPremium 更新
  }
);
```

**流れ:**
```
クライアント購入
    ↓
ReceiptVerificationService.verifyPurchaseAndUpdatePremium()
    ↓
Cloud Function: verifyPurchaseReceipt()
    ↓
Apple App Store / Google Play API で検証
    ↓
検証成功 → Firestore isPremium = true
検証失敗 → エラー返却（Firestore 更新なし）
```

### 3. Firestore セキュリティルール ✅

**ファイル:** `firestore.rules`

```firestore
// クライアントから isPremium を直接変更禁止
allow update: if isPremiumUnchanged
  && isValidUserCreate(newData);

// Cloud Functions のみが isPremium を更新可能
// (Firebase Admin SDK で認証回避)
```

**ルール内容:**

| 操作 | ユーザー | 権限 | 理由 |
|-----|--------|------|------|
| isPremium 読み取り | 本人 | ✅ | ステータス表示用 |
| isPremium 直接変更 | 本人 | ❌ | 不正防止 |
| isPremium 更新 | Cloud Functions | ✅ | 検証後のみ |

### 4. ローカルストレージ対策

**実装:** 購入後は以下の流れで更新
```dart
// ❌ 直接フラグを立てない
// isPremium = true;  // これは禁止

// ✅ サーバー検証後にフェッチ
_refreshUserData();  // Firestore から最新データ取得
```

### 5. 購入イベントログ

**Cloud Functions:** `premiumUpdatedAt` タイムスタンプ記録
```typescript
await db.collection('users').doc(uid).update({
  isPremium: true,
  premiumUpdatedAt: admin.firestore.Timestamp.now(),  // ログ
  premiumProduct: productId,  // 商品追跡
});
```

## 設定手順

### 1. Apple App Store Secret 設定

```bash
firebase functions:config:set apple.app_secret="YOUR_SHARED_SECRET"
```

App Store Connect → Apps → In-App Purchases で共有シークレットを取得

### 2. Google Play Service Account 設定

```bash
firebase functions:config:set google.service_account="$(cat /path/to/service-account.json | jq -c .)"
```

[Google Play Console](https://play.google.com/console) → 設定 → API とアクセス → サービスアカウント から JSON ファイルを取得

### 3. Firestore セキュリティルール 発行

```bash
firebase deploy --only firestore:rules
```

### 4. Cloud Functions デプロイ

```bash
cd functions
npm install
firebase deploy --only functions:verifyPurchaseReceipt
```

## テスト

### ローカルテスト

```bash
# Firebase Emulator で全体テスト
firebase emulators:start

# Firestore Emulator テスト
firebase emulators:exec "npm test"
```

### 検証テスト手順

#### iOS（Sandbox テスト）
1. TestFlight で Test User 作成
2. Sandbox App Store の商品を購入
3. App Store Connect でレシート検証

#### Android（Google Play Console テスト）
1. テストアカウント作成
2. Google Play Console → 管理 → ライセンステスト
3. テスト用APKで購入テスト

## セキュリティチェックリスト

### デプロイ前確認

- [ ] Apple App Secret を環境変数に設定
- [ ] Google Play Service Account を設定
- [ ] Cloud Functions をデプロイ
- [ ] Firestore セキュリティルールを発行
- [ ] isPremium フィールドがクライアントから変更不可か確認

### 本番環境確認

- [ ] レシート検証が正常に機能しているか
- [ ] Firestore ログに `premiumUpdatedAt` が記録されているか
- [ ] 検証失敗時にエラーが返却されているか
- [ ] ユーザーアクセスが正常にフィルタリングされているか

## トラブルシューティング

### Apple レシート検証失敗

**原因:** Sandbox vs Production の混在

```typescript
// Sandbox テストの場合
const isDev = true;
verified = await verifyAppleReceipt(receipt, productId, isDev);
```

### Google レシート検証エラー

**確認事項:**
- Service Account に `androidpublisher` 権限があるか
- Package Name が正確か
- Product ID（SKU）が完全一致しているか

### Firestore ルール エラー

```
FirebaseError: Missing or insufficient permissions
```

→ `firebase.rules` がデプロイされているか確認

## 監視・監査

### Firestore ログ確認

```firestore
// isPremium の更新を監視
function(db, 'users', uid) {
  return db.collection('users')
    .doc(uid)
    .get()
    .then(doc => doc.data().premiumUpdatedAt);
}
```

### Cloud Functions ログ確認

```bash
firebase functions:log --only verifyPurchaseReceipt
```

### 不正検出

```firestore
// 複数デバイスからの同時購入
function checkFraud(userId) {
  return (isPremium が true に変わった時刻) < (5分前)
    && (複数デバイスからのアクティビティ)
}
```

## 今後の改善

- [ ] レシート失効管理（サブスクリプション キャンセル検出）
- [ ] 複数デバイスでのライセンス共有検出
- [ ] 不正な premium フラグ変更の自動リセット
- [ ] 監査ログの詳細化
- [ ] リアルタイム不正検出アラート

## 参考資料

- [App Store Server Notifications](https://developer.apple.com/documentation/app-store-server-notifications)
- [Google Play Billing Library](https://developer.android.com/google-play/billing)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/start)
- [Cloud Functions for Firebase](https://firebase.google.com/docs/functions)
