# Phase 4: 最近見た施設 設計

## 背景

検索画面（`lib/views/search_screen.dart`）には検索キーワードのローカル履歴
（「最近の検索」、`CacheService.searchHistory`）が既に実装されていたが、
施設を開いた「閲覧履歴」は無く、気になった施設を再度見るには検索し直す
必要があった。検索キーワード履歴と同じ考え方（Hiveによるローカル保存、
サーバーに送らない個人的な履歴）で「最近見た施設」を追加する。

## 実装方針

### データモデル

`RecentFacilityEntry`（`lib/models/recent_facility_entry.dart`、新規）:
一覧カード表示に必要な最小限のフィールド（`id`/`name`/`category`/
`thumbnailUrl`）のみを保持する軽量モデル。`FacilityModel`全体をキャッシュ
すると情報が古くなりやすい（評価件数等は時間で変わる）ため、タップ後は
`/facility/:id`に遷移して最新の`FacilityModel`を取得し直す設計とした。

### 保存先

`CacheService`（既存、`lib/services/cache_service.dart`）に
`addRecentFacility`/`recentFacilities`/`clearRecentFacilities`を追加した。
既存の`search_history`と同じパターン（Hiveの`user`ボックスにJSON文字列として
保存、最大10件、同一IDは先頭に移動して重複排除）を踏襲している。

### 記録タイミング

`FacilityDetailViewModel._load()`（`lib/view_models/facility_detail_view_model.dart`）
内、施設データの取得に成功した直後に`CacheService.addRecentFacility()`を呼ぶ。
画面を開くたびに（`refresh()`経由でも）呼ばれるが、`addRecentFacility`は
同一施設を先頭に移動するだけなので実害はない。

### 表示

検索画面の検索前プロンプト（`_EmptyPrompt`）に「最近見た施設」セクションを
追加した。既存の「最近の検索」の上に配置し、横スクロールの小型カード
（`_RecentFacilityCard`、サムネイル+施設名+カテゴリ）で表示する。タップで
`/facility/:id`へ遷移する。「最近の検索」と同様に「全削除」ボタンを設けた。

`SearchViewModel`（`lib/view_models/search_view_model.dart`）の
`SearchState.recentFacilities`で保持し、画面初期化時（`_loadHistory()`）に
`CacheService.recentFacilities`から読み込む。

## 実装ファイル

- `lib/models/recent_facility_entry.dart` — 軽量モデル（新規）
- `lib/services/cache_service.dart` — `addRecentFacility`/`recentFacilities`/
  `clearRecentFacilities`を追加
- `lib/view_models/facility_detail_view_model.dart` — 施設取得成功時に記録
- `lib/view_models/search_view_model.dart` — `SearchState.recentFacilities`、
  読み込み・クリア処理を追加
- `lib/views/search_screen.dart` — `_EmptyPrompt`に「最近見た施設」セクション、
  `_RecentFacilityCard`ウィジェットを追加

## スコープ外（将来検討）

- ホーム画面への「最近見た施設」セクション表示
- 複数デバイス間での履歴同期（現状はこのデバイス内のローカル履歴のみ）
- 履歴の個別削除（現状は全削除のみ）
