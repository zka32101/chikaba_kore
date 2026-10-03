# Phase 4: クチコミの下書き保存 設計

## 背景

クチコミ投稿画面（`lib/views/write_review_screen.dart`）は入力内容を
`WriteReviewViewModel`の状態（Riverpod、`autoDispose`）のみで保持していた。
画面を閉じる（戻る、または誤ってアプリを閉じる）と入力内容は失われる。
長文を書いている途中で中断されると再入力が必要になるため、評価・コメントを
ローカル（Hive）に自動保存し、次回同じ施設のクチコミ投稿画面を開いたときに
復元する機能を追加した。

## スコープ

- 保存対象は「評価（★）」と「コメント本文」のみ。画像（`List<File>`）は
  `image_picker`が返す一時ファイルパスで、OSに一時ファイルを回収されたり
  パスが無効になったりする可能性があるため、下書き保存の対象外とした
  （画像を選び直す前提）。
- 下書きは施設ごとに1件（同じ施設のクチコミ投稿画面を開いたときのみ復元）。
- 投稿が完了したら下書きを削除する。

## 実装方針

### データモデル・保存先

`ReviewDraft`（`lib/models/review_draft.dart`、新規）: `rating`/`text`を
持つ軽量モデル。`CacheService`（既存、`lib/services/cache_service.dart`）に
`saveReviewDraft`/`getReviewDraft`/`clearReviewDraft`を追加した。既存の
`search_history`等と同じパターンで、Hiveの`user`ボックスに施設ID別のキー
（`review_draft_{facilityId}`）でJSON文字列として保存する。評価・コメントが
両方未入力の状態で保存しようとした場合は、既存の下書きを削除する（空の下書きを
残さない）。

### 自動保存・復元のタイミング

`WriteReviewViewModel`（`lib/view_models/write_review_view_model.dart`）の
コンストラクタで`CacheService.getReviewDraft()`を読み込み、下書きがあれば
初期状態に反映する。`setRating`/`setText`が呼ばれるたび（既存のUI操作の延長）に
`CacheService.saveReviewDraft()`で即時保存する。デバウンス等は行わず、Hiveの
書き込みは軽量なためシンプルに毎回保存する。投稿成功（`submit()`完了）時に
`clearReviewDraft()`で下書きを削除する。

### UI側の復元

`WriteReviewScreen`の`_textController`はViewModelの状態とは別にFlutterの
TextField用に保持されているため、`initState`でViewModelの初期状態
（下書き復元済み）から`_textController.text`に反映する。下書きが復元された
場合は一度だけスナックバーで「前回の入力内容を復元しました」と知らせる。

## 実装ファイル

- `lib/models/review_draft.dart` — 下書きモデル（新規）
- `lib/services/cache_service.dart` — `saveReviewDraft`/`getReviewDraft`/
  `clearReviewDraft`を追加
- `lib/view_models/write_review_view_model.dart` — 下書きの読み込み・自動保存・
  投稿完了時のクリア
- `lib/views/write_review_screen.dart` — `TextField`への復元反映、復元時の通知

バックエンド（Cloud Functions、firestore.rules）の変更は無い
（このデバイス内のみのローカル下書きで、サーバーには送らない）。

## スコープ外（将来検討）

- 画像の下書き保存（一時ファイルの永続化が必要になり実装規模が大きいため見送り）
- 複数デバイス間での下書き同期
- 複数件の下書き一覧（現状は施設ごとに最新1件のみ）
