# Phase 4: 訪問記録バッジ（実績）設計

## 背景

マイページ（`lib/views/main_tabs/settings_screen.dart`の`_ProfileStats`）には
「投稿」「お気に入り」「訪問」の3統計を表示する枠が既に用意されていたが、
「投稿」「訪問」はハードコードの`'0'`のままだった。これを実データで埋め、
ユーザーの継続利用を促す「実績バッジ」を追加する。

## 集計対象

「訪問」実績（`UserModel.visitCount`）は以下2つの行動の累計とする（施設の重複は
考慮しない。同じ施設に複数回レビューしても、お気に入りを「行ってきた」にしても
その都度+1する単純な累計行動回数）。

1. クチコミ（レビュー）投稿
2. お気に入りの状態を「行きたい」→「行ってきた」（`FavoriteStatus.willGo`）に
   変更したタイミング（最初から「行ってきた」で保存した場合も含む）

「行ってきた」から「行きたい」に戻しても実績は取り消さない（カウントは
増加のみで、ユーザーの行動実績という性質上、取り消しの概念を設けない）。

「投稿」統計（`UserModel.reviewCount`）はクチコミ投稿数のみを指す
（既存の「お気に入り」統計と区別するため）。

## バッジ（実績）の段階

`visitCount`の閾値に応じて、単一の称号バッジを算出する（`UserModel.visitBadgeLabel`、
クライアント側で算出。Firestoreには保存しない）。

| 閾値 | バッジ |
|---|---|
| 1件以上 | はじめての一歩 |
| 5件以上 | ご近所探検家 |
| 15件以上 | 地元マスター |
| 30件以上 | 近場レジェンド |

## カウントの更新

既存の「サブコレクション/ドキュメント作成 → Cloud Functionsでincrement」
パターン（`onFacilityHiddenGemVoteCreate`等）を踏襲する。

- `onReviewCreateUserStats`（`reviews/{reviewId}`のonCreate）: 投稿者の
  `users/{userId}.reviewCount`と`visitCount`を両方+1する。既存の
  `onReviewCreate`（連投レート制限のモデレーション用）とは別目的のため、
  同一パス・別名の独立したトリガーとして実装する。
- `onFavoriteWillGoUpdate`（`users/{userId}/favorites/{favoriteId}`の
  onWrite）: `status`が`'will_go'`に"なった"タイミングのみ`visitCount`を+1
  する。判定ロジックは`shouldIncrementVisitOnFavoriteWrite`
  （`functions/src/visitStats.ts`）に純粋関数として分離し、ユニットテストで
  境界値（既に`will_go`だった場合は対象外、`will_go`から戻した場合は対象外等）
  を検証する。

いずれも`reviewCount`/`visitCount`はCloud Functions（Admin SDK）経由のみが
更新できるよう、`firestore.rules`の`isValidUserCreate`/`isValidUserUpdate`で
クライアントからの直接変更を禁止する（`isPremium`/`isVerified`と同じ設計）。

## 表示の最新化

Cloud Functionsによる更新は非同期（投稿・お気に入り変更の直後には反映され
ない場合がある）なため、`authNotifierProvider`のキャッシュされた`UserModel`
ではなく、マイページ表示のたびにFirestoreから再取得する専用プロバイダ
（`userStatsProvider`、`FutureProvider.autoDispose`）を用意し、`_ProfileStats`
のみそちらを参照する。画面を開き直せば最新の実績が反映される。

## 実装ファイル

- `lib/models/user_model.dart` — `reviewCount`/`visitCount`フィールド、
  `visitBadgeLabel`ゲッターを追加
- `lib/providers/auth_provider.dart` — `userStatsProvider`追加
- `lib/views/main_tabs/settings_screen.dart` — `_ProfileStats`で実データ・
  バッジを表示
- `functions/src/visitStats.ts` / `visitStats.test.ts` — 判定ロジックと
  ユニットテスト
- `functions/src/onReviewCreateUserStats.ts` — レビュー投稿時の集計トリガー
- `functions/src/onFavoriteWillGoUpdate.ts` — お気に入り「行ってきた」時の
  集計トリガー
- `functions/src/index.ts` — export追加
- `firestore.rules` — `reviewCount`/`visitCount`のクライアント変更禁止

## スコープ外（将来検討）

- 施設の重複を除いたユニーク訪問施設数での集計
- バッジの複数同時表示・実績一覧画面
- 実績達成時のプッシュ通知・お祝いダイアログ
