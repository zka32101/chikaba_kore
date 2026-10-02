# Phase 4: 施設の「穴場」投票機能 設計

## 背景

「地元民が知っている隠れた穴場を共有する」というアイデアについて、実装範囲を検討した結果、
新規スポットを地図タップで登録するフルスコープ版（安心ルートのSpot投稿・承認フロー一式を
転用する想定）ではなく、既存施設に対する軽量な投票機能として実装した。クチコミの
「参考になった」リアクション（`docs/PHASE4_REVIEW_HELPFUL_VOTES_DESIGN.md`）と全く同じ
設計を、クチコミ単位ではなく施設単位に転用している。

## 既存の「穴波スコア」との違い

`FacilityModel.eccentricityScore`は「評価高い×レビュー少ない×地元民率高い」から自動算出
される客観的スコアで、既に施設詳細画面に表示されている。今回追加した`hiddenGemVoteCount`は
ユーザーが明示的に「ここは穴場だと思う」と投票する主観的な指標で、両者は別物として併存する
（自動スコアは地元民以外の訪問者には意味が分かりにくい場合があるため、分かりやすい投票制の
指標を補完する狙い）。

## 機能概要

- 施設詳細画面（基本情報セクション）に「穴場だと思う」ボタンを追加
- タップすると件数が+1され、ボタンがハイライト表示に変わる（取り消し不可）
- 投票数が`FacilityModel.hiddenGemVoteThreshold`（3件）以上になると
  「みんなが選ぶ穴場」バッジを表示

## 二重投票の防止と「投票済み」表示

`facilities/{facilityId}/hiddenGemVotes/{userId}`サブコレクションに投票を記録する。
docIdをuserIdにすることで、2回目の書き込みは`update`として扱われ、firestore.rulesで
`allow update: if false`としているため自動的に拒否される（クチコミの通報・「参考になった」
と同じ仕組み）。

投票済み一覧はクライアントから読み取れない設計（`allow read: if false`）のため、UI側の
「投票済み」表示はこのデバイス内のローカルキャッシュ（Hive）で行う。他デバイスでの投票状態
は反映されないが、再投票を試みてもサーバー側で拒否されるだけで実害はない。

## カウントの更新

`hiddenGemVotes/{userId}`作成をトリガーに、Cloud Functions（`onFacilityHiddenGemVoteCreate`）
が親`facilities/{facilityId}`の`hiddenGemVoteCount`を`FieldValue.increment(1)`で更新する。

施設詳細画面は`FacilityDetailViewModel`が保持する`state.facility`を表示に使っているため
（`facilityDetailProvider`とは別経路）、投票後はUI側（`_HiddenGemVoteSection`）から
`FacilityDetailViewModel.refresh()`を呼んで最新の`hiddenGemVoteCount`を反映する。

## 実装ファイル

- `lib/models/facility_model.dart` — `hiddenGemVoteCount`フィールド、`isHiddenGem`ゲッター、`hiddenGemVoteThreshold`定数を追加
- `lib/services/firestore_service.dart` — `voteHiddenGem`メソッド追加
- `lib/repositories/facility_repository.dart` — `voteHiddenGem`委譲メソッド追加
- `lib/providers/facility_provider.dart` — `hiddenGemVoteNotifierProvider`（投票操作）/`hiddenGemVoteCacheProvider`（ローカル投票済みキャッシュ）
- `lib/views/facility_detail_screen.dart` — `_HiddenGemVoteSection`ウィジェット追加
- `functions/src/onFacilityHiddenGemVoteCreate.ts` — `hiddenGemVoteCount`インクリメントトリガー
- `functions/src/index.ts` — export追加
- `firestore.rules` — `facilities/{facilityId}/hiddenGemVotes/{userId}`サブコレクションのルール追加

## スコープ外（将来検討）

- 新規スポット（未登録の場所）を地図タップで投稿する機能。安心ルートのSpot投稿・人力承認
  フロー（`docs/PHASE3_MODE_INTEGRATION_DESIGN.md`の未決定論点4で実装した`moderateSpot`
  Callable Function等の仕組み）を転用する想定だが、地図タップでの位置選択UIや専用の投稿・
  一覧・詳細画面が必要になり実装規模が大きいため見送った
- 「穴場」バッジが付いた施設だけのフィルタ・一覧表示
- 投票の取り消し
