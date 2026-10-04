# Phase 4: お気に入りリスト共有の一括追加機能 設計

## 背景

既存のお気に入りリスト共有機能（`docs/PHASE4_SHARED_FAVORITE_LISTS_DESIGN.md`、
PR#54）では、共有コードを受け取った側は各施設を一件ずつ開いて個別に
お気に入りに追加する必要があった。リスト全体をまとめて自分のお気に入りに
取り込めるよう、「すべて追加」ボタンを追加する。

## 実装方針

### 追加ロジック

`FavoriteNotifier`（`lib/providers/favorite_provider.dart`）に
`addFromSharedListItem(SharedListItem item)`を追加した。既存の`toggle()`は
`FacilityModel`（施設詳細の完全なデータ）を受け取るが、共有リストの各項目
（`SharedListItem`）は一覧表示用の軽量スナップショット（`facilityId`/
`facilityName`/`facilityThumbnailUrl`/`facilityCategory`のみ）のため、
別メソッドとして追加した。既にお気に入り済みの施設は`isFavorite`チェックで
スキップする（重複追加を避ける）。

### 上限（無料プラン）への対応

`FavoriteRepository.add()`は無料プランのお気に入り件数上限
（`AppConstants.freeFavoriteLimit`）に達すると例外を投げる既存の仕組みが
ある。一括追加はUI側（`_SharedListView._handleAddAll`）でリストの先頭から
順に`addFromSharedListItem`を呼び、上限到達の例外を検知した時点で中断し、
それまでに追加できた件数をスナックバーで報告する（全件失敗にはしない）。

### UI

`SharedListScreen`の`_SharedListView`（`lib/views/screens/shared_list_screen.dart`）
をConsumerWidgetからConsumerStatefulWidgetに変更し、リスト件数表示の横に
「すべて追加」ボタンを追加した。ログイン済みユーザーのみ表示する
（未ログインではお気に入りに追加できないため）。

## 実装ファイル

- `lib/providers/favorite_provider.dart` — `FavoriteNotifier.addFromSharedListItem`
- `lib/views/screens/shared_list_screen.dart` — `_SharedListView`に
  「すべて追加」ボタンと一括追加処理を追加

バックエンド（Cloud Functions、firestore.rules）の変更は無い
（既存の`favorites`サブコレクションへの個別書き込みをループするのみ）。

## スコープ外（将来検討）

- 一括追加前の確認ダイアログ（現状は即時実行）
- 追加しない施設を選んでの部分的な一括追加（現状は全件か上限到達までの前方一致）
