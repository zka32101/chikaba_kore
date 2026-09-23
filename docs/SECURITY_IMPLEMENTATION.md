# セキュリティ実装ガイド

## 概要

アプリ内課金機能のセキュリティを強化するための実装ガイドです。
課金基盤には RevenueCat を使用しており、Firestore の `isPremium` は
RevenueCat Webhook 経由でのみサーバー側から更新されます
（クライアントから直接更新することはできません）。

## 実装されたセキュリティ対策

### 1. RevenueCat Webhook による検証済み更新 ✅

**ファイル:** `functions/src/revenuecatWebhook.ts`

```typescript
// RevenueCat の Server Notifications を受信し、Firestore の isPremium を更新
export const revenuecatWebhook = functions.https.onRequest(
  async (req, res) => {
    // 1. Authorization ヘッダーで正当なリクエストか検証
    // 2. イベント種別（購入/更新/失効）を判定
    // 3. Firestore の isPremium 更新
  }
);
```

**利点:**
- クライアント側での改ざんを防止（購入検証は RevenueCat 側で実施済み）
- App Store/Google Play の実際の購入状態を RevenueCat が継続的に追跡
- 失効（`EXPIRATION`）イベントも自動的に反映される

**流れ:**
```
クライアント購入（RevenueCat SDK経由）
    ↓
RevenueCat が Apple/Google の購入を検証
    ↓
RevenueCat → Webhook 通知 → Cloud Functions: revenuecatWebhook()
    ↓
Authorization ヘッダー検証
    ↓
検証成功 → イベント種別に応じて Firestore isPremium を更新
検証失敗 → 401エラー返却（Firestore 更新なし）
```

### 2. イベント種別による付与・剥奪判定 ✅

**ファイル:** `functions/src/revenuecatWebhook.ts` の `decidePremiumUpdate()`

| イベント種別 | 判定 |
|---|---|
| `INITIAL_PURCHASE` / `RENEWAL` / `UNCANCELLATION` / `PRODUCT_CHANGE` | 付与（`isPremium: true`） |
| `EXPIRATION` | 剥奪（`isPremium: false`） |
| `CANCELLATION`（自動更新停止のみ、即座には失効しない） | 無視（状態維持） |
| その他未知のイベント | 無視（状態維持） |

純関数として分離されており、`functions/src/revenuecatWebhook.test.ts` でユニットテスト済み。

### 3. Firestore セキュリティルール ✅

**ファイル:** `firestore.rules`

```firestore
// isPremium フィールドの直接変更を禁止
function isValidUserUpdate(oldData, newData) {
  let isPremiumUnchanged = (('isPremium' in oldData) && (newData.isPremium == oldData.isPremium))
    || (!('isPremium' in oldData) && !('isPremium' in newData));
  return isPremiumUnchanged && isValidUserCreate(newData);
}
```

**ルール内容:**

| 操作 | ユーザー | 権限 | 理由 |
|-----|--------|------|------|
| isPremium 読み取り | 本人 | ✅ | ステータス表示用 |
| isPremium 直接変更 | 本人 | ❌ | 不正防止 |
| isPremium 更新 | Cloud Functions (`revenuecatWebhook`) | ✅ | Admin SDK 経由でルールをバイパス |

### 4. RevenueCat の app_user_id を Firebase UID に一致させる

**ファイル:** `lib/purchases/purchases_bootstrap.dart` の `linkPurchasesToUser()`

Webhook が受け取る `app_user_id` をそのまま `users/{uid}` のドキュメントIDとして
使えるよう、ログイン時（`auth_provider.dart`）に `Purchases.logIn(uid)` を呼ぶ。

### 5. Webhook の認証

**実装:** Authorization ヘッダーの秘密文字列による検証
```typescript
const authHeader = req.get('Authorization');
if (authHeader !== `Bearer ${expectedSecret}`) {
  res.status(401).send('Unauthorized');
  return;
}
```

### 6. 購入イベントログ

**Cloud Functions:** `premiumUpdatedAt` タイムスタンプ記録
```typescript
await admin.firestore().collection('users').doc(uid).update({
  isPremium: grant,
  premiumUpdatedAt: admin.firestore.Timestamp.now(),  // ログ
  premiumProduct: grant ? event.product_id ?? null : null,  // 商品追跡
});
```

## 設定手順

### 1. RevenueCat Webhook Secret 設定

```bash
firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET
```

RevenueCat ダッシュボード → Project Settings → Integrations → Webhooks で
同じ秘密文字列を Authorization header に設定する。

### 2. Firestore セキュリティルール 発行

```bash
firebase deploy --only firestore:rules
```

### 3. Cloud Functions デプロイ

```bash
cd functions
npm install
firebase deploy --only functions:revenuecatWebhook,functions:onReviewCreate
```

## テスト

### ローカルテスト

```bash
cd functions
npm run build
node --test lib/*.test.js
```

### 検証テスト手順

RevenueCat ダッシュボードの Webhook 設定画面から「Send Test Event」を送信し、
Cloud Functions のログでイベントを正しく受信・処理できるか確認する。

## セキュリティチェックリスト

### デプロイ前確認

- [ ] RevenueCat Webhook Secret を Cloud Functions の環境変数に設定
- [ ] RevenueCat ダッシュボードで Webhook URL・Authorization header を設定
- [ ] Cloud Functions をデプロイ
- [ ] Firestore セキュリティルールを発行
- [ ] isPremium フィールドがクライアントから変更不可か確認

### 本番環境確認

- [ ] RevenueCat の購入イベントが Webhook で正常に届いているか
- [ ] Firestore ログに `premiumUpdatedAt` が記録されているか
- [ ] Authorization 検証失敗時に401が返却されているか
- [ ] RevenueCat の `app_user_id` が Firebase UID と一致しているか

## トラブルシューティング

### Webhook が届かない / isPremium が更新されない

**確認事項:**
- RevenueCat ダッシュボードの Webhook URL が正しいデプロイ先を指しているか
- Authorization header の秘密文字列が一致しているか
- `linkPurchasesToUser` がログイン時に呼ばれ、`app_user_id` が Firebase UID と
  一致しているか

### Firestore ルール エラー

```
FirebaseError: Missing or insufficient permissions
```

→ `firestore.rules` がデプロイされているか確認

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
firebase functions:log --only revenuecatWebhook
```

## 今後の改善

- [ ] 複数デバイスでのライセンス共有検出
- [ ] 監査ログの詳細化
- [ ] リアルタイム不正検出アラート

## 参考資料

- [RevenueCat Webhooks](https://www.revenuecat.com/docs/integrations/webhooks)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/start)
- [Cloud Functions for Firebase](https://firebase.google.com/docs/functions)
