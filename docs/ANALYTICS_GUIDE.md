# 近場コレ - Analytics Dashboard ドキュメント

**バージョン**: 1.0.0  
**最終更新**: 2026年9月

---

## 目次

- [概要](#概要)
- [主要メトリクス](#主要メトリクス)
- [アーキテクチャ](#アーキテクチャ)
- [イベントトラッキング](#イベントトラッキング)
- [ダッシュボード機能](#ダッシュボード機能)
- [実装ガイド](#実装ガイド)
- [ベストプラクティス](#ベストプラクティス)
- [トラブルシューティング](#トラブルシューティング)

---

## 概要

近場コレの Analytics Dashboard は、ユーザー行動、施設の人気度、プラットフォーム全体のパフォーマンスを詳細に分析するための包括的なシステムです。

### 主な機能

- 📊 **リアルタイムメトリクス** — リアルタイム更新される主要指標
- 👥 **ユーザーアクティビティ分析** — ユーザー行動の追跡と分析
- 🏢 **施設分析** — 施設の人気度、レビュー、閲覧数
- 📈 **イベント分析** — ユーザーイベントのトラッキングと分析
- 🎯 **コホート分析** — ユーザーグループの長期トレンド分析
- 🔄 **リアルタイムストリーミング** — Firestore Stream による即座の更新

---

## 主要メトリクス

### ユーザーメトリクス

| メトリクス | 説明 |
|-----------|------|
| **Total Users** | 登録済みユーザー総数 |
| **Active Users (Daily)** | 本日アクティブなユーザー数 |
| **Active Users (Weekly)** | 先週1週間アクティブなユーザー数 |
| **Sessions Today** | 本日のセッション数 |
| **Avg Session Duration** | 平均セッション時間 |

### 施設メトリクス

| メトリクス | 説明 |
|-----------|------|
| **Total Facilities** | プラットフォーム上の施設総数 |
| **Total Reviews** | すべての施設のレビュー総数 |
| **Avg Rating** | プラットフォーム全体の平均評価 |
| **Views This Week** | 施設ごとの先週1週間の閲覧数 |
| **Reviews This Month** | 施設ごとの今月のレビュー数 |

### エンゲージメントメトリクス

| メトリクス | 説明 |
|-----------|------|
| **Facilities Searched** | ユーザーが検索した施設数 |
| **Reviews Created** | ユーザーが投稿したレビュー数 |
| **Favorites Added** | ユーザーが追加したお気に入り数 |
| **Top Categories** | ユーザーが最もよく閲覧するカテゴリ |

---

## アーキテクチャ

### データモデル

```dart
// イベントレベル
AnalyticsEvent {
  eventName: String           // "facility_viewed", "review_created" など
  userId: String
  properties: Map             // カスタムデータ
  timestamp: DateTime
  screen: String?
}

// ユーザーレベル
UserActivityMetrics {
  totalSessions: int
  facilitiesSearched: int
  reviewsCreated: int
  favoritesAdded: int
  topCategories: List<String>
}

// 施設レベル
FacilityAnalytics {
  totalViews: int
  totalReviews: int
  totalFavorites: int
  averageRating: double
  viewsThisWeek: int
}

// プラットフォーム全体
AnalyticsSummary {
  totalUsers: int
  activeUsersToday: int
  totalFacilities: int
  totalReviews: int
  eventCounts: Map<String, int>
}
```

### Firestore コレクション

```
firestore/
├── analytics_events/        # イベントログ
├── user_analytics/          # ユーザー集計
├── facility_analytics/      # 施設集計
├── analytics_summary/       # プラットフォーム集計
└── cohort_analysis/         # コホート分析
```

---

## イベントトラッキング

### トラッキング対象イベント

```dart
// 施設関連
await analyticsService.trackFacilityView(facilityId, userId);
await analyticsService.trackReviewCreation(facilityId, userId);
await analyticsService.trackFavoriteAction(facilityId, userId, 'add');

// カスタムイベント
await analyticsService.trackEvent(
  'screen_view',
  userId,
  screen: 'FacilityDetailScreen',
  properties: {'facilityId': facilityId},
);
```

### イベントプロパティの設計

✅ **推奨:**
```dart
await analyticsService.trackEvent(
  'search_completed',
  userId,
  properties: {
    'query': 'カフェ',
    'resultsCount': 42,
    'timeSpentSeconds': 15,
  },
);
```

❌ **非推奨:**
```dart
// 個人情報を含めない
await analyticsService.trackEvent(
  'user_searched',
  userId,
  properties: {
    'emailAddress': 'user@example.com',  // PII
  },
);
```

---

## ダッシュボード機能

### キーメトリクスセクション

4行のカードで最も重要な指標を表示：
- アクティブユーザー（本日・週間）
- 合計ユーザー
- セッション数
- 施設・レビュー数
- 平均評価
- 平均セッション時間

### 期間フィルター

`24時間 | 週間 | 1ヶ月 | 四半期 | 1年 | すべて`

### リアルタイム更新

Firestore Stream を使用：

```dart
ref.watch(analyticsSummaryStreamProvider)
ref.watch(userActivityStreamProvider(userId))
ref.watch(facilityAnalyticsStreamProvider(facilityId))
```

---

## 実装ガイド

### ステップ 1: サービスの初期化

```dart
final analyticsService = AnalyticsService();
```

### ステップ 2: イベントのトラッキング

```dart
@override
void initState() {
  super.initState();
  analyticsService.trackEvent(
    'screen_view',
    userId,
    screen: 'FacilityDetailScreen',
  );
}
```

### ステップ 3: ダッシュボード表示

```dart
GoRoute(
  path: '/analytics',
  builder: (context, state) => const AnalyticsDashboardScreen(),
),
```

### ステップ 4: Firestore セキュリティルール

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /analytics_events/{eventId} {
      allow write: if request.auth != null;
      allow read: if isAdmin();
    }

    match /user_analytics/{userId} {
      allow read: if request.auth.uid == userId || isAdmin();
      allow write: if isAdmin();
    }

    match /facility_analytics/{facilityId} {
      allow read;
      allow write: if isAdmin();
    }

    match /analytics_summary/{document=**} {
      allow read;
      allow write: if isAdmin();
    }

    function isAdmin() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

---

## ベストプラクティス

### 1. パフォーマンス

✅ **推奨:**
```dart
// イベント送信を非同期で実行
unawaited(analyticsService.trackEvent(...));
```

❌ **非推奨:**
```dart
// UI ブロッキング
await analyticsService.trackEvent(...);
```

### 2. メモリ管理

✅ **推奨:**
```dart
// .autoDispose で自動削除
final facilityAnalyticsProvider = FutureProvider.autoDispose
  .family<FacilityAnalytics?, String>(...);
```

### 3. キャッシング

```dart
// キャッシュをクリア
ref.invalidate(analyticsSummaryProvider);
```

### 4. Firestore最適化

- インデックスを作成
- バッチ書き込みを使用
- キャッシングを実装

---

## トラブルシューティング

### イベントがトラッキングされていない

**原因:**
- ユーザーが認証されていない
- Firestore ルールが書き込みを拒否している
- ネットワーク接続がない

**対処法:**
```dart
appLogger.d('Tracking event: $eventName for $userId');
```

### ダッシュボードのデータが更新されない

**対処法:**
```dart
ref.invalidate(analyticsSummaryProvider);
```

### パフォーマンスが低下している

**対処法:**
- イベントをバッチ処理
- インデックスを作成
- .autoDispose を使用

---

**最終更新**: 2026年9月11日  
**バージョン**: 1.0.0
