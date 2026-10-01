# Phase 4: クチコミの「参考になった」リアクション機能 設計

## 背景

Phase 4の新規機能として、クチコミ一覧の表示順序を改善する「参考になった」リアクション機能を
追加した。既存のクチコミ通報機能（`reviews/{reviewId}/reports/{userId}`）と同じ
「サブコレクション + docIdをuserIdにして二重操作を防ぐ」設計を転用している。

## 機能概要

- クチコミの下部（投稿時刻の横）に「参考になった」ボタンを追加
- タップすると件数が+1され、ボタンがハイライト表示に変わる（取り消し不可）
- クチコミのソート順に「参考になった順」を追加

## 二重投票の防止と「投票済み」表示

`reviews/{reviewId}/helpfulVotes/{userId}`サブコレクションに投票を記録する。docIdを
userIdにすることで、2回目の書き込みは（SDK視点では）`update`として扱われ、
firestore.rulesで`allow update: if false`としているため自動的に拒否される
（既存の通報機能と同じ仕組み）。

投票済みの一覧自体はクライアントから読み取れない設計（`allow read: if false`。通報一覧と
同様、Cloud Functionsが件数カウントのみ行う）ため、UI側で「このユーザーはどのクチコミに
投票済みか」を即座に表示するには別の手段が必要になる。都度Firestoreへ問い合わせる方式
（レビュー件数分のクエリが発生する）は避け、このデバイス内のローカルキャッシュ（Hive）に
投票済みのreviewIdを記録し、表示状態の判定にのみ使う方式を採用した。他デバイスでの投票
状態は反映されない（再投票を試みてもサーバー側で拒否されるだけで実害はない）というトレード
オフを許容している。

## カウントの更新

`helpfulVotes/{userId}`作成をトリガーに、Cloud Functions（`onReviewHelpfulVoteCreate`）が
親`reviews/{reviewId}`の`helpfulCount`を`FieldValue.increment(1)`で更新する。二重投票が
ルール側で防止されているため、このトリガーは「1回のonCreateにつき必ず+1してよい」という
前提で実装している（閾値判定等のロジックは無いため、通報機能のような専用の純関数ファイル
は設けていない）。

投票直後、クライアント側のカウント表示はローカルキャッシュのみを更新し（ボタンの見た目を
即座にハイライト表示へ切り替える）、実際の件数（`helpfulCount`）は次回のクチコミ一覧再読込
まで反映されない。Optimisticなカウント更新（即座に+1表示する）は実装の複雑さに対して
効果が小さいと判断し、スコープ外とした。

## 実装ファイル

- `lib/models/review_model.dart` — `helpfulCount`フィールド追加
- `lib/services/firestore_service.dart` — `voteHelpful`メソッド追加
- `lib/repositories/review_repository.dart` — `voteHelpful`委譲メソッド追加
- `lib/providers/review_provider.dart` — `reviewHelpfulNotifierProvider`（投票操作）/
  `helpfulVoteCacheProvider`（ローカル投票済みキャッシュ）
- `lib/views/widgets/review_item.dart` — `_HelpfulButton`ウィジェット追加
- `lib/view_models/facility_detail_view_model.dart` — ソート順`'helpful'`を追加
- `lib/views/facility_detail_screen.dart` — ソートメニューに「参考になった順」を追加
- `functions/src/onReviewHelpfulVoteCreate.ts` — `helpfulCount`インクリメントトリガー
- `functions/src/index.ts` — export追加
- `firestore.rules` — `reviews/{reviewId}/helpfulVotes/{userId}`サブコレクションのルール追加

## スコープ外（将来検討）

- 投票の取り消し（一度押したら解除できない）
- カウントのoptimistic update（投票直後に即座に件数表示を更新する）
- 複数デバイス間での「投票済み」状態の同期
