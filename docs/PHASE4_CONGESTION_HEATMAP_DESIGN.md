# Phase 4: 混雑ヒートマップ表示 設計

## 背景

既存の「今の混雑状況」機能（`docs/PHASE4_CONGESTION_REPORTS_DESIGN.md`、PR#53）は
直近30分以内の投稿から「今」の状況のみを集計していた。これとは別に、過去の投稿を
時間帯別に集計し「この施設は何時頃混みやすいか」という傾向を可視化する機能を追加する。

地図全体をヒートマップ表示するフルスコープ版（複数施設を地図上に重ねて表示）は
実装規模が大きいため見送り、まず施設詳細画面単位で「時間帯別の混雑しやすさ」を
表示する軽量版として実装した。

## 実装方針

### 集計ロジック

`CongestionService`（既存の抽象インターフェース）に`fetchHourlyPattern`を追加した。
`FirestoreCongestionService`（Firebase実装）は、対象施設の直近30日分の
`congestionReports`（最大500件）を取得し、投稿時刻の時（0-23時）ごとに
混雑レベルをスコア化（空いてる=0.0、普通=0.5、混んでる=1.0）して平均を算出する。
Cloud Functionsでの事前集計は行わず、クライアント側でその場で集計する
（投稿数がまだ少ないため、取得件数を絞ったクライアント集計で十分と判断）。

`LocalCongestionService`（Firebase未接続時のフォールバック）は常に
`CongestionHourlyPattern.empty`を返す（既存の`fetchStatus`と同じ設計）。

### データが少ない場合の扱い

`CongestionHourlyPattern.hasEnoughData`（集計対象の投稿総数が5件未満ならfalse）が
falseの間はヒートマップ自体を表示しない。少数の投稿だけで「混みやすい時間帯」を
断定すると誤解を招くため。

### 表示

施設詳細画面の「今の混雑状況」セクション（`CongestionSection`）の投稿ボタンの下に、
24時間分の縦棒を並べたヒートマップ（`_HourlyHeatmap`）を追加した。各時間帯の
平均混雑度に応じて緑（空いてる）→オレンジ（普通）→赤（混んでる）のグラデーションで
色分けする。投稿が無い時間帯はグレー表示。

## 実装ファイル

- `lib/models/congestion_report.dart` — `CongestionHourlyPattern`モデルを追加
- `lib/services/congestion_service.dart` — `fetchHourlyPattern`を抽象インターフェースと
  `LocalCongestionService`に追加
- `lib/firebase/firebase_congestion_service.dart` — `fetchHourlyPattern`の集計実装
- `lib/providers/congestion_provider.dart` — `congestionHourlyPatternProvider`を追加
- `lib/views/widgets/congestion_section.dart` — `_HourlyHeatmap`ウィジェットを追加

バックエンド（Cloud Functions、firestore.rules）の変更は無い
（既存の`congestionReports`は誰でも読み取り可能なため、新規クエリの追加のみ）。

## スコープ外（将来検討）

- 地図全体への複数施設ヒートマップ表示
- 曜日別の集計（現状は時間帯のみ、曜日は区別しない）
- 投稿数が多くなった場合のCloud Functionsによる事前集計（現状はクライアント集計）
