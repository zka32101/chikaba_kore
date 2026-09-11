# 近場コレ - Community Features ドキュメント

**バージョン**: 1.0.0  
**最終更新**: 2026年9月

---

## 目次

- [概要](#概要)
- [主要機能](#主要機能)
- [アーキテクチャ](#アーキテクチャ)
- [データモデル](#データモデル)
- [ローカルQ&Aシステム](#ローカルqaシステム)
- [ユーザー評判システム](#ユーザー評判システム)
- [フォロー機能](#フォロー機能)
- [コミュニティフィード](#コミュニティフィード)
- [実装ガイド](#実装ガイド)
- [ベストプラクティス](#ベストプラクティス)
- [トラブルシューティング](#トラブルシューティング)

---

## 概要

近場コレの Community Features は、地元民と訪問者が直接つながる場を提供し、リアルタイムな情報交換を実現するシステムです。

### 主な機能

- 🎯 **ローカルQ&A** — 位置情報付きの質問と回答
- 👑 **ユーザー評判** — 信頼度スコアとローカル専門家バッジ
- 👥 **フォロー機能** — 有用なユーザーをフォロー
- 📰 **コミュニティフィード** — フォロワーの活動をタイムラインで表示
- 📊 **コミュニティ統計** — 都市別の活動分析
- ⭐ **評価システム** — 回答の役立ち度で評判を構築

---

## 主要機能

### 1. ローカルQ&A

訪問者が地元民に直接質問できるシステム。

**特徴:**
- 位置情報付きの質問投稿
- 24時間有効期限（自動クローズ）
- カテゴリ分類と タグシステム
- 複数回答サポート
- 回答の役立ち度投票（アップボート）
- 質問者による回答の受け入れ機能
- 統計情報（質問数、回答数、ビュー数）

**Q&Aのフロー:**

```
訪問者
  │
  ├─ 質問投稿「子連れで入りやすい蕎麦屋は？」
  │  ├─ 位置情報: 東京駅周辺 500m
  │  ├─ カテゴリ: 飲食店
  │  └─ タグ: [子連れ向け] [蕎麦] [駅近]
  │
  └─ 有効期限: 24時間（自動クローズ）

    ↓ (地元民にプッシュ通知)

地元民 A
  └─ 回答「△△がおすすめです」
     ├─ 地元民バッジ: ⭐ Verified（50投稿以上）
     └─ レビュー数: 127件

地元民 B
  └─ 回答「〇〇はどうでしょう」
     ├─ 地元民バッジ: なし
     └─ レビュー数: 8件

    ↓ (訪問者が評価)

訪問者
  ├─ 回答Aにアップボート → 地元民Aの評判 +1
  └─ 回答Bを受け入れ → 地元民Bの評判 +5（ボーナス）
```

### 2. ユーザー評判システム

ユーザーの信頼度と専門性を可視化。

**評判スコア計算:**

```
信頼スコア (0.0-1.0) = 
  (レビュー数 / 100) × 0.3 +
  (役立ち回答数 / 50) × 0.3 +
  (コミュニティ貢献度 / 100) × 0.4
```

**ローカル専門家バッジ:**
- 条件: 同一都市で50投稿以上
- 表示: ⭐ Verified Local（バッジ）
- 効果: 回答表示順序を上げる

**ユーザーバッジ:**

| バッジ | 条件 | 効果 |
|--------|------|------|
| 🌟 Verified Local | 50投稿以上 | 回答を上位表示 |
| ✓ Trusted Reviewer | 20投稿以上 | 小さいバッジ表示 |
| 📝 Active Contributor | QA回答10+いいね100+ | フィード強調 |

### 3. フォロー機能

有用なユーザーをフォローして、活動をトラッキング。

**フォロー時に取得:**
- フォロワーの新しい回答
- 投稿したレビュー
- コミュニティ活動
- バッジの獲得情報

### 4. コミュニティフィード

フォロー中のユーザーの活動をタイムラインで表示。

**フィード項目:**
- 新しい質問投稿
- 回答の投稿
- レビューの投稿
- バッジの獲得
- フォロワーの増減

---

## アーキテクチャ

### システム構成図

```
┌──────────────────────────────────────────────┐
│       Flutter UI Layer                       │
│ (Community Q&A Screen, User Profile, Feed)  │
└────────────────────┬─────────────────────────┘
                     │
        ┌────────────▼──────────────┐
        │   Riverpod Providers      │
        │  (State Management)       │
        └────────────┬──────────────┘
                     │
        ┌────────────▼──────────────┐
        │  CommunityService         │
        │  (Business Logic)         │
        └────────────┬──────────────┘
                     │
      ┌──────────────┼──────────────┐
      │              │              │
 ┌────▼────┐   ┌────▼────┐   ┌────▼────┐
 │Questions │   │Answers  │   │User Rep │
 │(Firestore)  │(Firestore)  │(Firestore)
 └─────────┘   └─────────┘   └─────────┘
```

### Firestore コレクション構造

```
firestore/
├── community_questions/
│   ├── {questionId}
│   │   ├── userId: "user_123"
│   │   ├── question: "子連れで..."
│   │   ├── category: "dining"
│   │   ├── city: "Tokyo"
│   │   ├── location: GeoPoint(35.6762, 139.7674)
│   │   ├── createdAt: 2026-09-11T10:00:00Z
│   │   ├── expiresAt: 2026-09-12T10:00:00Z
│   │   ├── answerCount: 3
│   │   ├── isAnswered: true
│   │   └── status: "open|closed|archived"
│   │
│   └── {questionId}/messages/ (回答のサブコレクション)
│       ├── {answerId}
│       │   ├── userId: "user_456"
│       │   ├── answer: "〇〇がおすすめ"
│       │   ├── upvotes: 5
│       │   ├── isAccepted: true
│       │   └── isLocalExpert: true
│       └── ...
│
├── user_reputation/
│   ├── {userId}
│   │   ├── reviewCount: 127
│   │   ├── helpfulAnswers: 23
│   │   ├── communityContribution: 45
│   │   ├── trustScore: 0.82
│   │   ├── isLocalExpert: true
│   │   ├── badges: ["verified_local", "trusted_reviewer"]
│   │   ├── followerCount: 42
│   │   └── followingCount: 18
│
├── user_following/
│   └── {followingId}
│       ├── followerId: "user_123"
│       ├── followingId: "user_456"
│       └── createdAt: 2026-09-11T12:00:00Z
│
├── community_feed/
│   └── {feedId}
│       ├── userId: "user_123"
│       ├── type: "answer_given|question_asked|review_posted"
│       ├── title: "ローカルQ&Aで回答"
│       ├── questionId: "q_456"
│       └── createdAt: 2026-09-11T13:30:00Z
│
└── community_stats/
    └── {city}
        ├── totalQuestions: 342
        ├── totalAnswers: 891
        ├── topContributorsCount: 15
        ├── activeUsersThisMonth: 128
        └── topTags: ["cafe", "ramen", "family-friendly"]
```

---

## データモデル

### CommunityQuestion

質問オブジェクト：

```dart
CommunityQuestion {
  id: String
  userId: String
  userName: String
  userAvatarUrl: String
  city: String
  location: GeoPoint?          // 質問位置
  question: String             // 質問テキスト
  category: String             // 飲食, 観光, etc
  tags: List<String>          // 複数タグ
  createdAt: DateTime
  expiresAt: DateTime         // 24時間後
  isAnswered: bool
  answerCount: int
  viewCount: int
  status: String              // open/closed/archived
}
```

### CommunityAnswer

回答オブジェクト：

```dart
CommunityAnswer {
  id: String
  questionId: String
  userId: String
  userName: String
  userAvatarUrl: String
  userReviewCount: int        // 信頼度指標
  isLocalExpert: bool         // ⭐ バッジ
  answer: String
  images: List<String>        // 画像URL
  createdAt: DateTime
  updatedAt: DateTime?
  upvotes: int                // 役立ち投票
  downvotes: int
  isAccepted: bool            // 質問者が選択
}
```

### UserReputation

ユーザー評判オブジェクト：

```dart
UserReputation {
  userId: String
  reviewCount: int            // レビュー投稿数
  helpfulAnswers: int        // 役立つ回答数
  communityContribution: int // QA貢献度
  trustScore: double         // 0.0-1.0
  isLocalExpert: bool        // Verified Local
  badges: List<String>       // バッジリスト
  followerCount: int
  followingCount: int
  createdAt: DateTime
  lastUpdatedAt: DateTime
}
```

---

## ローカルQ&Aシステム

### 質問投稿

```dart
final communityService = CommunityService();

final questionId = await communityService.postQuestion(
  userId: 'user_123',
  userName: '田中太郎',
  userAvatarUrl: 'https://...',
  city: 'Tokyo',
  question: '子連れで入りやすい蕎麦屋はありますか？',
  category: 'dining',
  tags: ['子連れ向け', '蕎麦', '駅近'],
  location: GeoPoint(35.6762, 139.7674),  // 可選
);
```

### 質問検索

```dart
// カテゴリ別に質問を取得
final questions = await communityService.getQuestions(
  'Tokyo',
  category: 'dining',
  isAnswered: false,  // 未回答のみ
);

// ストリーム（リアルタイム）
final questionsStream = communityService.streamQuestions('Tokyo');
```

### 回答投稿

```dart
final answerId = await communityService.answerQuestion(
  questionId: 'q_001',
  userId: 'user_456',
  userName: '佐藤次郎',
  userAvatarUrl: 'https://...',
  answer: '〇〇蕎麦がおすすめです。子連れフレンドリーで...',
  images: ['https://storage.../image1.jpg'],
);
```

### 回答の評価

```dart
// 役立つと思った回答にアップボート
await communityService.upvoteAnswer(
  'q_001',  // questionId
  'a_123',  // answerId
);

// 質問者が最も役立つ回答を選択
await communityService.acceptAnswer(
  'q_001',     // questionId
  'a_123',     // answerId
  'user_789',  // 質問者のID（検証用）
);
// → 回答者の reputation に大きなボーナス（+5 contribution）
```

---

## ユーザー評判システム

### 評判スコア計算

```dart
信頼スコア =
  (レビュー数 / 100) × 0.3 +
  (役立ち回答数 / 50) × 0.3 +
  (コミュニティ貢献度 / 100) × 0.4
```

**例:**
- ユーザーA: レビュー100件、回答50件、貢献度100
  - スコア = (100/100)×0.3 + (50/50)×0.3 + (100/100)×0.4 = 1.0 ✅ 完全な専門家

- ユーザーB: レビュー30件、回答10件、貢献度15
  - スコア = (30/100)×0.3 + (10/50)×0.3 + (15/100)×0.4 = 0.225

### ユーザー評判取得

```dart
final reputation = await communityService.getUserReputation('user_123');

print('信頼スコア: ${reputation.trustScore}');  // 0.0 - 1.0
print('ローカル専門家: ${reputation.isLocalExpert}');  // 50投稿以上
print('バッジ: ${reputation.badges}');  // ['verified_local']
print('フォロワー: ${reputation.followerCount}');
```

### ストリーミング

```dart
// ユーザー評判をリアルタイム監視
final reputationStream = communityService.streamUserReputation('user_123');
```

---

## フォロー機能

### ユーザーをフォロー

```dart
await communityService.followUser(
  'user_123',  // フォロワーのID
  'user_456',  // フォロー対象のID
);
// → フォロワー数とフォロー数が自動更新
```

### ユーザーをアンフォロー

```dart
await communityService.unfollowUser(
  'user_123',  // フォロワーのID
  'user_456',  // アンフォロー対象のID
);
```

---

## コミュニティフィード

### フィード取得

```dart
// フォロー中のユーザーの活動をタイムラインで取得
final feedItems = await communityService.getCommunityFeed(
  'current_user_id',
  limit: 50,
);

for (final item in feedItems) {
  print('${item.userName}: ${item.title}');  // 「田中太郎: ローカルQ&Aで回答を投稿」
}
```

**フィード項目タイプ:**
- `question_asked` — 質問投稿
- `answer_given` — 回答投稿
- `review_posted` — レビュー投稿
- `user_followed` — ユーザーフォロー

---

## 実装ガイド

### ステップ 1: サービス初期化

```dart
final communityService = CommunityService();
```

### ステップ 2: Q&A画面に統合

```dart
GoRoute(
  path: '/community/:city',
  builder: (context, state) => CommunityQAScreen(
    city: state.pathParameters['city']!,
    userId: currentUserId,
  ),
),
```

### ステップ 3: プロバイダーで状態管理

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 質問リストを取得
    final questionsAsync = ref.watch(
      communityQuestionsStreamProvider('Tokyo'),
    );
    
    // ユーザー評判を取得
    final reputationAsync = ref.watch(
      userReputationStreamProvider('user_123'),
    );

    return questionsAsync.when(
      data: (questions) => ListView(
        children: questions
            .map((q) => Text(q.question))
            .toList(),
      ),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### ステップ 4: 通知連携

質問が投稿されたとき、カテゴリに関心のある地元民に通知：

```dart
// Cloud Function (バックエンド)で実装
exports.onQuestionCreated = functions.firestore
  .document('community_questions/{questionId}')
  .onCreate(async (snap) => {
    const question = snap.data();
    
    // タグに関心のあるユーザーを検索
    const interestedUsers = await db.collection('users')
      .where('interests', 'array-contains-any', question.tags)
      .where('city', '==', question.city)
      .get();
    
    // プッシュ通知を送信
    for (const user of interestedUsers.docs) {
      await sendNotification(user.id, {
        type: 'localQA',
        questionId: question.id,
        title: '新しいQ&Aが投稿されました',
      });
    }
  });
```

---

## ベストプラクティス

### ✅ 推奨

```dart
// 1. 質問のカテゴリと タグを指定
await communityService.postQuestion(
  category: 'dining',  // 明確に分類
  tags: ['family-friendly', 'lunch'],  // 具体的なタグ
);

// 2. ユーザー評判を確認して表示順序を調整
final topAnswers = answers
  .where((a) => a.isLocalExpert || a.isAccepted)
  .toList();
answers.sort((a, b) => b.upvotes.compareTo(a.upvotes));

// 3. 24時間が経過した質問は自動クローズ
if (question.expiresAt.isBefore(DateTime.now())) {
  question.status = 'closed';
  await updateQuestion(question);
}
```

### ❌ 非推奨

```dart
// 質問にカテゴリなしで投稿
await communityService.postQuestion(
  question: 'おすすめどこ？',
  category: '',  // ❌ 空カテゴリ
);

// 回答を無分別に表示
answers.sort((a, b) => b.createdAt.compareTo(a.createdAt));  // ❌ 時系列のみ

// 期限切れ質問のチェックなし
if (questions.isEmpty) return;  // ❌ 期限確認なし
```

---

## トラブルシューティング

### Q&Aが表示されない

**原因:**
1. 都市設定が正しくない
2. ステータスが 'closed' または 'archived'
3. 有効期限が切れている

**解決方法:**
```dart
// 質問取得時にフィルタを確認
final questions = await communityService.getQuestions(
  'Tokyo',  // 都市を明確に指定
);

// 手動でフィルタリング
final activeQuestions = questions.where((q) {
  return q.status == 'open' && 
         q.expiresAt.isAfter(DateTime.now());
}).toList();
```

### ユーザー評判が更新されていない

**原因:**
1. バックグラウンドで reputation 更新が失敗
2. Firestore ルール設定誤り

**解決方法:**
```dart
// 手動で reputation を再計算
final reputation = await communityService.getUserReputation('user_123');
print('Current trustScore: ${reputation.trustScore}');

// Firestore ルール確認
match /user_reputation/{userId} {
  allow read: if true;
  allow write: if request.auth.uid == userId || isAdmin();
}
```

### 通知が来ない

**原因:**
1. タグの一致がない
2. ユーザーがミュート設定している
3. 地理的範囲外

**解決方法:**
```dart
// ユーザーの interests を確認
final user = await getUser(userId);
print('Interests: ${user.interests}');

// 質問のタグを確認
final question = await getQuestion(questionId);
print('Tags: ${question.tags}');
```

---

**最終更新**: 2026年9月11日  
**バージョン**: 1.0.0
