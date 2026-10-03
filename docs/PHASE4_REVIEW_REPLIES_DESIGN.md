# Phase 4: クチコミへの返信・リプライ機能 設計

## 背景

クチコミには評価・コメント本文・「参考になった」投票はあったが、他ユーザーが
クチコミに直接反応して会話する手段が無かった。「このお店、まだ営業してますか？」
のような質問や、投稿者への感謝コメントなどを残せるよう、クチコミへの返信
（リプライ）機能を追加する。

## 権限（ユーザーに確認済み）

施設オーナーのような専用ロールはこのアプリに存在しない
（管理者＝`isAdmin()`のcustom claimのみ）ため、返信は運営限定の「公式回答」
ではなく、ログイン済みの全ユーザーが投稿できるSNS的なスレッド形式とした。
既存の安全ルート機能の「投稿へのコメント」（`spotComments`）と同じ考え方。

## 実装方針

### データ構造

`reviews/{reviewId}/replies/{replyId}`サブコレクションに返信を保存する
（`ReviewReply`モデル、`lib/models/review_reply.dart`）。`userId`/
`userNickname`/`userProfileImageUrl`/`text`/`createdAt`のみを持つシンプルな
構造。編集・削除・通報は本バージョンでは実装しない（投稿のみ）。

`ReviewModel.replyCount`（新規フィールド）に返信件数を非正規化カウントし、
クチコミ一覧で「返信 (N)」とバッジ表示する。既存の`helpfulCount`と同じ
「サブコレクション作成 → Cloud Functionsでincrement」パターン
（`onReviewReplyCreate`）を踏襲する。

### 権限制御

`firestore.rules`で、返信の閲覧は誰でも可能（`allow read: if true`）、
作成はログイン済みかつ`userId`が自分自身であることを要求する
（`request.auth.uid == request.resource.data.userId`）。更新・削除は
`allow update, delete: if false`で禁止する（本バージョンでは未実装）。

### UI

`ReviewItem`（`lib/views/widgets/review_item.dart`）の「参考になった」ボタンの
下に「返信」セクション（`_ReplySection`、新規）を追加した。タップで返信一覧と
入力欄を展開する（デフォルトは折りたたみ、クチコミ一覧が縦に長くなり過ぎない
ようにするため）。展開時は`reviewRepliesProvider`（`FutureProvider.family`）で
返信一覧を取得し、`_ReplyItem`で表示する。ログイン済みユーザーのみ入力欄を
表示し、`ReviewReplyNotifier.submit()`で投稿後、`reviewRepliesProvider`を
invalidateして一覧を更新する。

## 実装ファイル

- `lib/models/review_reply.dart` — 返信モデル（新規）
- `lib/models/review_model.dart` — `replyCount`フィールドを追加
- `lib/services/firestore_service.dart` — `getReviewReplies`/`addReviewReply`
- `lib/repositories/review_repository.dart` — 委譲メソッド追加
- `lib/providers/review_provider.dart` — `reviewRepliesProvider`/
  `reviewReplyNotifierProvider`
- `lib/views/widgets/review_item.dart` — `_ReplySection`/`_ReplyItem`ウィジェット
- `functions/src/onReviewReplyCreate.ts` — `replyCount`インクリメントトリガー
- `functions/src/index.ts` — export追加
- `firestore.rules` — `reviews/{reviewId}/replies/{replyId}`のルール追加

## スコープ外（将来検討）

- 返信の編集・削除
- 返信への通報・モデレーション
- 返信へのさらなる返信（2階層以上のスレッド）
- 返信投稿時の投稿者への通知
