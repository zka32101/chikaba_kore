# 近場コレ - Notification System Upgrade ドキュメント

**バージョン**: 1.0.0  
**最終更新**: 2026年9月

---

## 目次

- [概要](#概要)
- [主要機能](#主要機能)
- [アーキテクチャ](#アーキテクチャ)
- [データモデル](#データモデル)
- [通知タイプ](#通知タイプ)
- [実装ガイド](#実装ガイド)
- [ユーザー設定](#ユーザー設定)
- [スマート配信機能](#スマート配信機能)
- [ベストプラクティス](#ベストプラクティス)
- [トラブルシューティング](#トラブルシューティング)

---

## 概要

近場コレの Notification System Upgrade は、ユーザーエンゲージメント向上と通知疲れ防止を両立させる包括的な通知システムです。

### 主な機能

- 📱 **通知センター** — 全通知を一元管理するアプリ内画面
- ⚙️ **ユーザー設定** — 通知種類ごとに細かく制御
- 🎯 **スマート配信** — ユーザー設定に基づいた最適な配信
- 📊 **通知統計** — 未読数、本日数、タイプ別集計
- 🏷️ **リッチ通知** — 画像、メタデータ、優先度レベル
- 🔔 **複数チャネル** — FCM + ローカル通知 + アプリ内通知
- ♻️ **自動クリーンアップ** — 30日後の自動削除

---

## 主要機能

### 1. 通知センター

アプリ内に専用の通知管理画面を提供：

**表示内容:**
- 全通知のリスト表示（時系列）
- 未読・本日・合計の統計
- 通知タイプ別フィルタリング
- 優先度順・時系列ソート
- 未読バッジ（青いドット）

**操作:**
- タップ：通知を既読にして詳細へ遷移
- スワイプ削除：通知を削除
- 長押し：アーカイブ・ミュート実行

**外観:**
```
┌─────────────────────────┐
│  📬 通知センター        │ ⚙️ 🔄
├─────────────────────────┤
│ 未読: 3  本日: 7  合計:42│
├─────────────────────────┤
│ [すべて ▼] [新順 ▼]     │
├─────────────────────────┤
│ 🔴 新着レビュー        ●│
│    豆の館に新しいレビュー│
│    32分前              │
│                         │
│ 🟡 施設更新           ●│
│    営業時間が変更...    │
│    2時間前             │
│                         │
│ 🔵 いいね通知         │
│    あなたのレビューに...│
│    昨日                │
└─────────────────────────┘
```

### 2. ユーザー設定

ユーザーが通知を完全にコントロール：

**種別ごとの制御:**
- 施設の更新通知（有効/無効）
- 新着レビュー通知（有効/無効）
- いいね通知（有効/無効）
- コミュニティ通知（有効/無効）
- キャンペーン通知（有効/無効）

**配信方法の制御:**
- サウンド再生（有効/無効）
- バイブレーション（有効/無効）
- 通知の自動バッチ化（有効/無効）

**施設ミュート:**
- 特定の施設の通知をすべてミュート
- ミュート済み施設リスト表示
- いつでも解除可能

**静かな時間帯:**
- 開始時刻・終了時刻を設定
- その時間帯は重要な通知のみ配信

### 3. 通知統計

リアルタイム統計情報を提供：

**表示される指標:**
- 未読通知数
- 本日の通知数
- 合計通知数
- 通知タイプ別の集計
- 最後の通知時刻

---

## アーキテクチャ

### システム構成図

```
┌─────────────────────────────────────────────────┐
│            外部トリガー (Backend)              │
│  (新レビュー, いいね, 施設更新, etc.)           │
└────────────────────┬────────────────────────────┘
                     │
        ┌────────────▼─────────────┐
        │  Cloud Functions / API   │
        │  (通知ロジック判定)       │
        └────────────┬─────────────┘
                     │
      ┌──────────────┼──────────────┐
      │              │              │
┌─────▼──────┐ ┌────▼────┐ ┌──────▼──────┐
│ FCM (推送)  │ │Firestore│ │ 統計更新    │
│  デバイス送│ │ 保存    │ │ (バッチ)   │
└─────┬──────┘ └────┬────┘ └──────┬──────┘
      │             │             │
      └─────────────┼─────────────┘
                    │
      ┌─────────────▼────────────┐
      │   Flutter アプリ         │
      │ ┌──────────────────────┐│
      │ │ 通知センター         ││
      │ │ (表示・管理・設定)   ││
      │ └──────────────────────┘│
      └──────────────────────────┘
```

### データモデル

#### AppNotification (アプリ内通知)

```dart
AppNotification {
  id: String                        // 一意ID
  userId: String                    // 対象ユーザー
  type: NotificationType            // 通知種類
  priority: NotificationPriority    // 優先度
  title: String                     // タイトル
  body: String                      // 本文
  imageUrl: String?                 // 画像URL
  metadata: Map<String, dynamic>    // 施設ID等
  timestamp: DateTime               // 作成日時
  isRead: bool                      // 既読フラグ
  isArchived: bool                  // アーカイブ
  readAt: DateTime?                 // 既読日時
  expiresAt: DateTime?              // 有効期限
}
```

#### NotificationPreferences (ユーザー設定)

```dart
NotificationPreferences {
  userId: String
  enableFacilityUpdates: bool       // 施設更新
  enableReviews: bool               // 新着レビュー
  enableLikes: bool                 // いいね
  enableCommunity: bool             // コミュニティ
  enableAnnouncements: bool         // お知らせ
  enablePromotions: bool            // キャンペーン
  enableSoundNotifications: bool    // サウンド
  enableVibration: bool             // バイブレーション
  batchNotifications: bool          // 自動バッチ化
  batchWindowMinutes: int           // バッチ時間窓（分）
  mutedFacilityIds: Set<String>     // ミュート施設
  quietHoursStart: DateTime?        // 静か時間開始
  quietHoursEnd: DateTime?          // 静か時間終了
  lastUpdatedAt: DateTime?          // 更新日時
}
```

#### NotificationStats (統計)

```dart
NotificationStats {
  userId: String
  totalNotifications: int           // 合計数
  unreadNotifications: int          // 未読数
  todayNotifications: int           // 本日数
  notificationsByType: Map          // タイプ別集計
  lastNotificationAt: DateTime?     // 最後の通知
}
```

### Firestore コレクション構造

```
firestore/
├── notifications/
│   └── {userId}/
│       └── messages/
│           ├── {notificationId}
│           │   ├── type: "newReview"
│           │   ├── title: "豆の館にレビューが追加"
│           │   ├── isRead: false
│           │   └── timestamp: 2026-09-11T12:30:00Z
│           └── ...
│
├── notification_preferences/
│   └── {userId}
│       ├── enableReviews: true
│       ├── enableFacilityUpdates: true
│       ├── mutedFacilityIds: ["facility_123"]
│       └── quietHoursStart: ...
│
└── notification_stats/
    └── {userId}
        ├── unreadNotifications: 3
        ├── todayNotifications: 7
        ├── totalNotifications: 342
        └── lastNotificationAt: 2026-09-11T14:15:00Z
```

---

## 通知タイプ

### NotificationType Enum

| タイプ | 説明 | トリガー | アイコン |
|--------|------|---------|--------|
| **facilityUpdate** | 施設情報が更新 | 営業時間変更、休業通知等 | 📍 |
| **newReview** | 施設に新しいレビューが追加 | レビュー投稿完了 | 💬 |
| **reviewLike** | 自分のレビューにいいね | いいね操作 | ❤️ |
| **favoriteFacility** | お気に入り施設の新情報 | 施設更新 & お気に入り | ⭐ |
| **localQA** | ローカルQ&Aへの回答 | 質問に回答が追加 | ❓ |
| **community** | コミュニティ活動 | フォロー、メンション等 | 👥 |
| **announcement** | 一般的なお知らせ | アプリ内告知 | 📢 |
| **promotion** | キャンペーン・プロモーション | キャンペーン開始 | 🎁 |

### NotificationPriority Enum

| レベル | 説明 | 配信タイミング |
|--------|------|--------------|
| **low** | 低優先度 | 時間をかけてバッチ配信 |
| **normal** | 標準 | 通常通り配信 |
| **high** | 高優先度 | 即座に配信（静か時間帯も除外）|

---

## 実装ガイド

### ステップ 1: サービスの初期化

```dart
// main.dart または root widget
final service = EnhancedNotificationService();
```

### ステップ 2: 通知の送信

```dart
final service = EnhancedNotificationService();

await service.sendNotification(
  userId: 'user_123',
  type: NotificationType.newReview,
  title: '新着レビュー',
  body: '豆の館に新しいレビューが追加されました',
  priority: NotificationPriority.normal,
  metadata: {
    'facilityId': 'facility_001',
    'reviewId': 'review_456',
  },
);
```

### ステップ 3: 通知をユーザーに表示

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = 'current_user_id';
    
    // 未読通知をリアルタイム取得
    final unreadAsync = ref.watch(
      unreadNotificationsStreamProvider(userId),
    );

    return unreadAsync.when(
      data: (notifications) => Text('未読: ${notifications.length}'),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### ステップ 4: 通知センター画面の表示

```dart
// ルーター設定
GoRoute(
  path: '/notifications',
  builder: (context, state) => NotificationCenterScreen(
    userId: currentUserId,
  ),
),

// または
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => NotificationCenterScreen(userId: userId),
  ),
);
```

### ステップ 5: ユーザー設定の更新

```dart
final service = EnhancedNotificationService();

// 施設をミュート
await service.muteFacility(userId, facilityId);

// ユーザー設定を更新
final prefs = NotificationPreferences(
  userId: userId,
  enableReviews: true,
  enablePromotions: false,
  batchNotifications: true,
  batchWindowMinutes: 30,
);
await service.updatePreferences(userId, prefs);
```

### ステップ 6: 通知設定をプロバイダーで監視

```dart
class SettingsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(
      notificationPreferencesProvider(userId),
    );

    return prefsAsync.when(
      data: (prefs) => ListView(
        children: [
          SwitchListTile(
            title: Text('新着レビュー'),
            value: prefs.enableReviews,
            onChanged: (value) {
              ref.read(enhancedNotificationServiceProvider)
                  .updatePreferences(
                    userId,
                    prefs.copyWith(enableReviews: value),
                  );
            },
          ),
        ],
      ),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

---

## ユーザー設定

### 設定の保存場所

設定は Firestore `notification_preferences` コレクションに保存：

```json
{
  "userId": "user_123",
  "enableFacilityUpdates": true,
  "enableReviews": true,
  "enableLikes": true,
  "enableCommunity": true,
  "enableAnnouncements": true,
  "enablePromotions": false,
  "enableSoundNotifications": true,
  "enableVibration": true,
  "batchNotifications": true,
  "batchWindowMinutes": 30,
  "mutedFacilityIds": ["facility_123", "facility_456"],
  "quietHoursStart": "2026-09-11T22:00:00Z",
  "quietHoursEnd": "2026-09-11T08:00:00Z",
  "lastUpdatedAt": "2026-09-11T14:30:00Z"
}
```

### デフォルト設定

新規ユーザーのデフォルト設定：

```dart
NotificationPreferences(
  userId: userId,
  enableFacilityUpdates: true,      // デフォルト有効
  enableReviews: true,              // デフォルト有効
  enableLikes: true,                // デフォルト有効
  enableCommunity: true,            // デフォルト有効
  enableAnnouncements: true,        // デフォルト有効
  enablePromotions: false,          // デフォルト無効（プレミアム向け）
  enableSoundNotifications: true,   // デフォルト有効
  enableVibration: true,            // デフォルト有効
  batchNotifications: true,         // デフォルト有効
  batchWindowMinutes: 30,           // 30分ごとにバッチ送信
)
```

---

## スマート配信機能

### 1. ユーザー設定に基づいた配信

```dart
final shouldSend = await service.shouldSendNotification(
  userId,
  NotificationType.facilityUpdate,
  facilityId: 'facility_001',
);

if (shouldSend) {
  // 通知を送信
  await service.sendNotification(...);
}
```

### 2. 施設ミュート機能

特定の施設からの通知をすべてミュート：

```dart
// 施設をミュート
await service.muteFacility(userId, facilityId);

// ミュート解除
await service.unmuteFacility(userId, facilityId);
```

### 3. 静か時間帯

設定時間帯は低優先度の通知のみ配信：

```dart
final prefs = NotificationPreferences(
  userId: userId,
  quietHoursStart: DateTime(2026, 9, 11, 22, 0),  // 夜10時
  quietHoursEnd: DateTime(2026, 9, 11, 8, 0),     // 朝8時
);

await service.updatePreferences(userId, prefs);
```

### 4. 自動バッチ化

複数の通知を時間窓内に集約：

```dart
// プレファレンスで有効化
final prefs = NotificationPreferences(
  userId: userId,
  batchNotifications: true,
  batchWindowMinutes: 30,  // 30分ごとに集約
);
```

---

## ベストプラクティス

### ✅ 推奨

```dart
// 1. ユーザー設定を確認してから送信
if (await service.shouldSendNotification(userId, type)) {
  await service.sendNotification(...);
}

// 2. 意味のあるメタデータを含める
await service.sendNotification(
  userId: userId,
  title: 'レビュー追加',
  body: '豆の館に新しいレビュー',
  metadata: {
    'facilityId': 'facility_123',  // 重要：タップ時の遷移に使用
    'reviewId': 'review_456',
  },
);

// 3. ユーザー設定は自動で表示
// NotificationCenterScreen が自動で管理
```

### ❌ 非推奨

```dart
// ユーザー設定を無視して送信
await service.sendNotification(...);  // ❌ shouldSendNotification を確認していない

// メタデータなしで送信
await service.sendNotification(
  userId: userId,
  title: '通知',
  body: '何か起きました',
  metadata: {},  // ❌ 遷移先を指定していない
);

// 大量の通知を一度に送信
for (int i = 0; i < 1000; i++) {
  await service.sendNotification(...);  // ❌ ユーザーの通知疲れ
}
```

---

## トラブルシューティング

### 通知が配信されていない

**原因:**
1. ユーザー設定で該当通知タイプが無効
2. 施設がミュートされている
3. 静か時間帯に低優先度通知送信
4. Firestore ルールで書き込み拒否

**解決方法:**
```dart
// 1. 設定を確認
final prefs = await service.getPreferences(userId);
print('Reviews enabled: ${prefs.enableReviews}');

// 2. ミュート確認
print('Muted facilities: ${prefs.mutedFacilityIds}');

// 3. shouldSendNotification でテスト
final result = await service.shouldSendNotification(
  userId,
  NotificationType.newReview,
  facilityId: 'facility_123',
);
print('Should send: $result');
```

### 通知が重複している

**原因:**
1. FCM と ローカル通知の両方が配信
2. バッチ処理のタイミング問題

**解決方法:**
```dart
// フォアグラウンド時はローカル通知のみ
FirebaseMessaging.onMessage.listen((message) {
  if (message.notification != null) {
    _localNotifications.show(...);  // ローカルのみ
  }
});
```

### 統計が更新されていない

**原因:**
1. `notification_stats` コレクション書き込み権限がない
2. バッチ処理が失敗

**解決方法:**
```dart
// Firestore ルールを確認
match /notification_stats/{userId} {
  allow read: if request.auth.uid == userId;
  allow write: if request.auth.uid == userId || isAdmin();
}

// 手動で統計を再計算
await service.getNotificationStats(userId);  // 再取得
```

### メモリ使用量が多い

**原因:**
1. 古い通知が削除されていない
2. ストリーム購読が多すぎる

**解決方法:**
```dart
// 1. クリーンアップスケジューラーを実行
// 定期的にクリーンアップ（毎日深夜など）
await service.cleanupExpiredNotifications(userId);

// 2. ストリーム購読を制限
// .autoDispose を使用して未使用時に自動削除
final notificationsAsync = ref.watch(
  notificationsStreamProvider(userId),  // autoDispose 付き
);
```

---

**最終更新**: 2026年9月11日  
**バージョン**: 1.0.0
