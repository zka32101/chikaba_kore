# 地図コンポーネント統合設計

## 概要

近場まっぷ（chikaba_map）とあんしんみち（project-039）は、どちらも `google_maps_flutter` を
利用しているが、地図の役割・UI・データレイヤーが大きく異なる。本ドキュメントは、両者を
Phase 3（1アプリ内でのモード統合）で共存させるための設計方針を整理する。

## 現状比較

| | 近場まっぷ `MapScreen` | あんしんみち `RealMapRouteView` |
|---|---|---|
| 役割 | 周辺施設を自由に探索する全画面地図 | 1本の経路をコンパクトに確認するプレビュー |
| 表示 | 全画面 `GoogleMap` | `AspectRatio(1)` のカード内、角丸クリップ |
| データ | `Marker` の集合（施設ごと） | `Polyline`（区間ごとの安心スコア色分け）+ 現在地/目的地の2マーカー |
| 操作性 | ズーム・パン自由、検索バー、カテゴリフィルタ、マーカータップで詳細 | 表示のみ（`zoomControlsEnabled: false`, `mapToolbarEnabled: false`） |
| カメラ制御 | 現在地取得時に `animateCamera(newLatLngZoom)` | ルート変更時に `animateCamera(newLatLngBounds)` でルート全体にフィット |
| 状態管理 | `MapViewModel`（Riverpod `StateNotifier`、`MapState`） | `RealMapRouteView` はステートレス、`route`/`currentLat`/`currentLon` を親から受け取る |
| 色分けロジック | なし | `AppTheme.comfortScoreColor(segment.comfortScore)` |
| 座標変換ユーティリティ | なし（`GoogleMap` の緯度経度をそのまま使用） | `MapProjection`（模式図描画・投稿キャンバスと共有、実地図では不使用） |

両者とも `GoogleMapController` を保持しカメラをアニメーションさせる、という骨格は同じだが、
「何を描画するか」「どう操作させるか」は用途ごとに全く異なる。

## 統合方針: 共通レイヤーとモード固有レイヤーの分離

**「1つの巨大な地図ウィジェットに全機能を詰め込む」のではなく、地図の骨格（カメラ制御・
ベース設定）だけを共通化し、描画内容（マーカー/ポリライン）とインタラクションは
モードごとに独立させる。** 理由:

- 施設探索と経路プレビューでは望ましい操作性が逆（自由操作 vs 操作抑制）
- データモデルが別（`FacilityModel` の集合 vs `RouteResult`/`RoadSegment`）
- 無理に1ウィジェットに統合すると分岐だらけの巨大コンポーネントになり、どちらの用途にも
  最適化されない

### 共通化する部分（`lib/views/widgets/map/` に切り出す）

1. **`MapCameraController`** — `GoogleMapController` のラップ。
   - `animateToPosition(LatLng, {double zoom})`
   - `animateToBounds(LatLngBounds, {double padding})`
   - dispose 管理
   - 両アプリの「取得した位置/範囲にカメラを合わせる」処理を共通化する
2. **`MapBaseOptions`** — `GoogleMap` に渡す基本オプションのプリセット
   （`mapType`, `myLocationButtonEnabled` 等のデフォルト値）。用途ごとに上書き可能にする
3. **スコア色分けヘルパー** — `AppTheme.comfortScoreColor` 相当の「スコア→色」関数を
   共通ユーティリティ化。近場まっぷの「穴場スコア」等、将来スコア可視化が増えた際に流用できる

### モード固有として残す部分

- マーカー/ポリラインの構築ロジック（`MapViewModel._buildMarkers` 相当、`RealMapRouteView.build`
  内のポリライン構築相当）
- 検索バー・カテゴリフィルタ等のオーバーレイUI（近場まっぷ固有）
- コンパクトカード表示・ルートフィット挙動（あんしんみち固有）
- 状態管理（`MapViewModel` は Riverpod `StateNotifier`、`RealMapRouteView` はステートレス
  — 無理に揃えず、各モードに適した形を維持する）

## Phase 3 でのUI構成イメージ

ホーム画面に「お店を探す」「安全ルートを探す」のモード切り替えを設けた場合、地図タブの
中身を以下のように構成できる:

```
MapTabScreen
  ├─ ModeSwitcher（お店を探す / 安全ルートを探す）
  ├─ 施設探索モード: 既存の MapScreen 相当
  │    GoogleMap + MapCameraController + 施設マーカー + 検索/フィルタUI
  └─ 安全ルートモード: あんしんみち由来の経路表示相当
       GoogleMap + MapCameraController + ポリライン + 現在地/目的地マーカー
```

`MapCameraController` と `MapBaseOptions` を共有することで、2つのモードのコード量を
減らしつつ、それぞれの UI/UX には手を加えない。

## 今回のスコープ

本ドキュメントは設計整理のみ。project-039 は別リポジトリ（書き込み権限なし）のため、
実際に `MapCameraController` 等を両リポジトリで共有するには、Phase 2（Firebase統合・
リポジトリ統合）以降の対応が前提となる。chikaba_map 側での先行実装は、次のいずれかの
タイミングで着手するのが妥当:

- 近場まっぷ側で「経路案内」的な機能（施設への道順表示等）が必要になったとき
  （そのとき初めて `MapCameraController` 等の共通レイヤーを作る実利が生まれる）
- 1リポジトリへの統合（Phase 3）に着手するとき

## 参考: 座標変換ユーティリティについて

あんしんみちの `MapProjection`（緯度経度⇔画面座標）は、模式図描画・投稿キャンバスでの
タップ位置→座標変換に使われており、実地図（`GoogleMap`）を使う場合は不要
（`GoogleMap` 自体が緯度経度で完結するため）。近場まっぷは実地図のみを使う設計のため、
`MapProjection` 自体の移植は現時点では不要と判断する。
