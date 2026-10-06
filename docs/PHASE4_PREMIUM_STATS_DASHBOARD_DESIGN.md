# Phase 4: プレミアム限定の詳細統計ダッシュボード 設計

## 背景

マイページの`_ProfileStats`は「投稿」「お気に入り」「訪問」の3件のみを
表示する簡易な統計だった（PR#57で実データ化）。プレミアム会員向けの差別化
特典として、既存の統計データを組み合わせたより詳しい内訳を見られる
「詳細統計」画面を追加する。

新規のバックエンド処理・新規Firestoreコレクションは作らず、既存の
データソース（`UserModel.reviewCount`/`visitCount`、お気に入り一覧、
ローカルキャッシュの投票履歴）を集計・可視化するだけの画面として実装した。

## 表示項目

- クチコミ投稿数・訪問実績（`UserModel.reviewCount`/`visitCount`、
  `userStatsProvider`から取得。既存のマイページ統計と同じソース）
- 訪問実績バッジ（`UserModel.visitBadgeLabel`）
- 「参考になった」投票数・「穴場だと思う」投票数
  （`helpfulVoteCacheProvider`/`hiddenGemVoteCacheProvider`の件数。
  いずれもこの端末内のローカルキャッシュのみを集計対象とするため、
  画面上に「この端末内の記録」である旨を明記する）
- お気に入りの「行きたい」/「行ってきた」の内訳（横棒グラフ）
- カテゴリ別のお気に入り件数（横棒グラフ、`FacilityModel.category`で集計）

## アクセス制御

`StatsDashboardScreen`（`lib/views/screens/stats_dashboard_screen.dart`）は
`authNotifierProvider`の`isPremium`を見て、非プレミアムの場合は統計の代わりに
プレミアム誘導ビュー（`_PremiumRequiredView`）を表示する。マイページからは
誰でも導線（`/premium/stats`）を辿れるようにし、プレミアムでない場合に画面側で
ブロックする設計とした（非プレミアムの場合にリンク自体を隠すより、「こんな
機能がある」と知ってもらえる方がアップグレードの動機になりやすいため）。

バックエンド側の権限制御は不要（表示専用の画面で、新規の書き込み・読み取り
エンドポイントを追加しないため）。

## 実装ファイル

- `lib/views/screens/stats_dashboard_screen.dart` — ダッシュボード画面（新規）
- `lib/config/router.dart` — `/premium/stats`ルートを追加
- `lib/views/main_tabs/settings_screen.dart` — 「詳細統計」への導線を追加

## スコープ外（将来検討）

- 時系列でのクチコミ投稿数・訪問実績の推移グラフ（現状は累計のみ）
- 他ユーザーとの比較（ランキング等）
- CSVエクスポート
