# Phase 4: クチコミの画像ギャラリー表示 設計

## 背景

施設詳細画面のクチコミは各投稿ごとに画像（`ReviewModel.imageUrls`）を表示できるが、
画像がどのクチコミに写真を貼ったかを一件ずつ探す必要があった。クチコミ本文を読まずに
「この施設の実際の様子」を写真だけで一覧したいユーザー向けに、全クチコミの画像を
横断的にまとめたサムネイルギャラリーをクチコミセクションの先頭に追加する。

新規のバックエンド処理は不要（既存のクチコミ取得結果をクライアント側で集計するだけ）。

## 実装方針

`FacilityDetailViewModel`は`_loadReviews()`で施設のクチコミを最大50件まで一括取得し、
`FacilityDetailState.reviews`に保持している（フィルター・ソート前の全件）。この
`reviews`から画像URLをフラット化するだけでギャラリーの元データが作れるため、新規の
Firestoreクエリは追加せず、既存の取得結果を再利用する。

- `FacilityDetailState.allReviewImageUrls`（新規ゲッター）: `reviews`を新着順に並べ替え、
  各クチコミの`imageUrls`を`expand`でフラット化したもの。レビューのフィルター・ソート
  設定（`reviewMinRating`/`reviewSortBy`）には影響されない（ギャラリーは常に全件対象）。
- `ReviewImageGallery`（新規ウィジェット、`lib/views/widgets/review_image_gallery.dart`）:
  画像URLのリストを受け取り、横スクロールのサムネイル一覧を表示する。画像が0件の場合は
  何も表示しない。
- サムネイルタップ時の拡大表示は、クチコミ単体の画像表示（`ReviewItem._buildImages`）と
  同じく既存の`FullscreenImageScreen`を再利用する（タップした画像を起点に、ギャラリー内の
  全画像をスワイプで閲覧できる）。
- `_buildReviews`（`lib/views/facility_detail_screen.dart`）内、「クチコミ」ヘッダー
  （件数バッジ）の直後、評価フィルター・ソート行の直前に`ReviewImageGallery`を配置した。

## 実装ファイル

- `lib/view_models/facility_detail_view_model.dart` — `allReviewImageUrls`ゲッターを追加
- `lib/views/widgets/review_image_gallery.dart` — ギャラリーウィジェット（新規）
- `lib/views/facility_detail_screen.dart` — `_buildReviews`にギャラリーを組み込み

## スコープ外（将来検討）

- ギャラリー専用のフルスクリーン一覧画面（現状はクチコミ詳細と同じビューアーを再利用）
- 画像をアップロードしたクチコミへのジャンプ機能
- 施設一覧・検索結果カードへの代表写真表示との連携
