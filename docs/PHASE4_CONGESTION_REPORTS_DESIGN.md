# Phase 4: 施設の「今の混雑状況」共有機能 設計

## 背景

Phase 4では、project-039（あんしんみち）の既存機能移植とは別に、近場まっぷ本体の新規機能として
「施設の今の混雑状況をユーザー同士で共有する」機能を追加する。地図系機能拡張の方向性（
`docs/INTEGRATION_PLAN_ANSHINMICHI.md`のPhase4「機能拡張」）の第一弾。

## 機能概要

- 施設詳細画面に「今の混雑状況」セクションを追加
- ユーザーは「空いてる / 普通 / 混んでる」の3段階で現在の混雑状況を投稿できる
- 直近30分以内の投稿（最大5件）から多数決で集計し、バッジ表示する
- Google Mapsの「ライブ混雑状況」に近い実況性重視の設計（古い投稿は集計対象外にする）

## データモデル

Firestore `congestionReports`コレクション（トップレベル、既存の`reviews`と同じフラット構成）:

```
congestionReports/{reportId}
  facilityId: string
  level: 'empty' | 'normal' | 'crowded'
  submitterId: string
  createdAt: Timestamp
```

承認制は設けない。クチコミのような営利的な不正投稿リスクが低く、主観的な実況情報という性質上、
投稿後すぐに反映される方がUXとして自然なため。

## 書き込み経路

`congestionReports`のfirestore.rulesは`allow create, update, delete: if false`で
クライアントからの直接書き込みを一切禁止している。投稿は`submitCongestionReport`
Callable Function経由で行い、サーバー側（Admin SDK）で連投レート制限（同一ユーザー・
同一施設への投稿は10分に1回まで）を適用する。クライアント側に同等のチェックを実装すると
悪意のあるクライアントに回避されるため、サーバー側のみで判定する。

## 集計方式

クライアント側（`FirestoreCongestionService.fetchStatus`）が直接Firestoreを読み取り、
直近30分以内・最新5件の投稿を取得して多数決で集計する。サーバー側での事前集計
（Cloud Functionsバッチ等）は行わない。読み取り専用のクエリであり、投稿経路のみ
サーバー側でレート制限していれば悪用リスクが低いため、実装コストと一貫性のバランスを
取ってクライアント集計とした。

## 実装ファイル

- `lib/models/congestion_report.dart` — `CongestionLevel`/`CongestionReport`/`CongestionStatus`
- `lib/services/congestion_service.dart` — 抽象インターフェース + Local実装
- `lib/firebase/firebase_congestion_service.dart` — Firestore（取得）+ Cloud Functions（投稿）実装
- `lib/providers/congestion_provider.dart` — `congestionServiceProvider`/`congestionStatusProvider`/`congestionReportNotifierProvider`
- `lib/views/widgets/congestion_section.dart` — 施設詳細画面に埋め込むウィジェット
- `lib/views/facility_detail_screen.dart` — 営業時間セクションとクチコミセクションの間に配置
- `functions/src/submitCongestionReport.ts` + テスト — Callable Function
- `firestore.rules` / `firestore.indexes.json` — ルール・複合インデックス追加

## スコープ外（将来検討）

- 混雑状況の時系列グラフ・曜日/時間帯別の傾向表示
- プッシュ通知連携（「よく行くお店が空いています」等）
- 投稿者の信頼度による重み付け（スポット投稿系の`computeTrustWeight`と同様の仕組み）
