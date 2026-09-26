# Phase 3: 1アプリ内でのモード統合 設計

## 概要

`docs/INTEGRATION_PLAN_ANSHINMICHI.md` のPhase 3「1アプリ内でのモード統合」を具体化する設計。
近場まっぷ（chikaba_map）とあんしんみち（project-039）を1つのFlutterアプリ・1リポジトリに統合し、
地図タブ内で「お店を探す」「安全ルートを探す」のモードを切り替えられるようにする。

## 前提（Phase 1/2で決定済みの事項）

- 認証: Google Sign-Inをベースに、コメント投稿等にのみ電話番号認証を追加リンク（`docs/AUTH_STRATEGY_DESIGN.md`）
- Firebase: `chikaba-map` プロジェクトに統一済み（`.firebaserc`設定済み、project-039用アプリ登録はユーザー側残作業）
- 課金: RevenueCatに統一済み
- 通知: `ForegroundBannerQueue`パターンに統一済み
- 地図の骨格（`MapCameraController`/`MapBaseOptions`）の共通化方針は`docs/MAP_COMPONENT_INTEGRATION_DESIGN.md`で設計済み・未実装
- モード切り替えの粒度: **地図タブ内でモード切替**（ユーザー確認済み。ボトムナビにタブを追加したり、アプリ全体を切り替えたりはしない）

## 現状の技術的差異（実装調査より）

| | chikaba_kore（近場まっぷ） | project-039（あんしんみち） |
|---|---|---|
| ルーティング | `go_router`。`ShellRoute`で4タブ（home/map/favorites/settings）＋独立ルート多数 | `go_router`未使用。`MaterialApp`の素の名前付きルート4つ（`/`, `/update-required`, `/onboarding`, `/home`）＋`Navigator.push`によるモーダル的画面遷移 |
| ホーム画面 | タブ構成（ホーム/地図/お気に入り/マイページ） | タブなし。単一`Scaffold`のハブ画面。AppBarアクション4つ（投稿確認/みんなの声/お知らせ/設定）＋FAB「塗って投稿」。経路探索機能自体をホーム画面が内包 |
| Provider構成 | 機能別ファイルに分割（`auth_provider.dart`, `billing_provider.dart`, `facility_provider.dart`等） | `lib/viewmodels/providers.dart`に集約。`firebaseAvailableProvider`の真偽で実装を出し分ける三項演算子パターンが14箇所 |
| データ層 | Repository→Serviceの2層、Firebase未接続時は簡易フォールバックのみ | 「抽象IF（`lib/services/`）＋Firebase実装（`lib/firebase/`）＋Local実装（`lib/services/`内）」の3層構造で統一 |
| Firestoreコレクション | `facilities`, `reviews`(+`reports`サブコレクション), `users`(+`favorites`サブコレクション) | `spotComments`, `brightnessSpots`, `shadeSpots`, `announcements`, `users` |

コレクション名の衝突は`users`のみ。フィールドが異なるため統合時はスキーマのマージが必要（後述）。

## 統合方針

### 1. リポジトリ統合の進め方

「1アプリ内統合」である以上、最終的に1つの`pubspec.yaml`・1リポジトリにまとまる必要がある。
project-039のコードをchikaba_koreへ**移植**する（サブモジュール化やmonorepo化はしない。
両アプリともプレローンチでユーザー0のため、複雑な仕組みを導入するコストに対してメリットが薄い）。

移植順序（依存の少ないものから）:
1. `lib/models/` — データモデル（`RouteResult`, `RoadSegment`, `SpotSummary`等）。他への依存が少ない
2. `lib/services/` — 抽象IF＋Local実装
3. `lib/firebase/` — Firebase実装
4. ロジック層（`RouteSearchService`等）
5. UI層（`lib/views/`配下の各画面）
6. `lib/viewmodels/providers.dart`は移植せず、chikaba_kore方式（機能別ファイル）に**分割し直す**（後述）

### 2. Provider構成の統合方針

project-039の「`firebaseAvailableProvider`による出し分け」パターン自体は3層構造の要であり有用なので**残す**。
ただし1ファイルへの集約はchikaba_koreの既存方針と合わないため、機能単位でファイルを分割する。

新設するProviderファイル（chikaba_kore側の命名規則に合わせる）:
- `lib/providers/safety_route_provider.dart` — `routeSearchServiceProvider`, `roadNetworkRepositoryProvider`, ルート検索状態
- `lib/providers/spot_provider.dart` — `spotSubmissionServiceProvider`, `spotListServiceProvider`, `spotVoteServiceProvider`
- `lib/providers/spot_comment_provider.dart` — `spotCommentServiceProvider`
- `lib/providers/announcement_provider.dart` — `announcementServiceProvider`
- `lib/providers/verification_provider.dart` — `verificationServiceProvider`（電話番号認証。`AUTH_STRATEGY_DESIGN.md`のCloud Functions連携もここに実装）

既存の`firebaseAvailableProvider`相当は、chikaba_koreにはまだ存在しない（現状は`try/catch`でのフォールバックのみ）ため、
`lib/providers/firebase_provider.dart`として新設し、上記いずれの新設Providerからも参照できるようにする。

### 3. 地図タブ内モード切替の設計

`lib/views/main_tabs/map_screen.dart`を以下のように拡張する:

```
MapScreen
  ├─ ModeSwitcher（SegmentedButton等: 「お店を探す」/「安全ルートを探す」。状態は StateProvider<MapMode> で管理）
  ├─ 施設探索モード（既存実装をそのまま維持）
  │    GoogleMap + 施設マーカー + 検索バー + カテゴリフィルタ + 施設ボトムシート
  └─ 安全ルートモード（project-039のHomeReady状態相当を移植）
       ├─ GoogleMap + MapCameraController + ポリライン（RealMapRouteView相当）
       ├─ 「目的地を選ぶ」ボタン → DestinationPickerViewをボトムシート/モーダルで表示
       ├─ FAB「塗って投稿」→ PaintSubmissionView
       └─ オーバーフローメニュー（AppBarのアイコン）→「みんなの声」「お知らせ」への遷移
```

`MapCameraController`/`MapBaseOptions`（`docs/MAP_COMPONENT_INTEGRATION_DESIGN.md`で設計済み）は
このタイミングで実装する。施設探索モードと安全ルートモードの両方から利用することで、
初めて「共通化の実利」が生まれる（同ドキュメントで示した実装タイミングの条件に合致）。

### 4. 周辺機能（投稿確認・コメント・お知らせ・本人確認）の配置

| project-039の画面 | 統合後の配置 |
|---|---|
| `SpotsListView`（投稿確認） | 地図タブ・安全ルートモードのオーバーフローメニューから独立画面へ遷移（`/safety-route/spots`） |
| `SpotCommentsListView`（みんなの声） | 同上（`/safety-route/comments`）。電話番号認証が必要な投稿操作はここに集約 |
| `AnnouncementsListView`（お知らせ） | Phase 3スコープ外とし先送り。chikaba_koreに類似機能が無く、通知バナー（Phase1で統合済み）である程度代替できるため。将来的にマイページ内「お知らせ」項目として統合を検討（Phase 4候補） |
| `PaintSubmissionView`（塗って投稿） | 安全ルートモードのFABから遷移（`/safety-route/submit`） |
| `PhoneVerificationView`（本人確認） | マイページ（設定画面）に「本人確認」セクションを追加し、そこから遷移。安全ルートモードのコメント投稿時に未確認ならここへ誘導 |
| `PaywallView`（課金誘導） | 既存の`PremiumScreen`に統合済みのRevenueCat基盤を再利用し、個別のPaywallViewは作らない |

### 5. Firestoreスキーマ統合

`users`コレクションのみ両アプリで名前が重複する。フィールドを合算する（互いのフィールドは削らない）:

```
users/{uid}
  # chikaba_kore由来
  nickname, profileImageUrl, userType, selectedCity, isPremium, createdAt, updatedAt
  # project-039由来（追加）
  isVerified
```

`isVerified`はCloud Functions（`syncVerificationStatus`相当）経由でのみ更新可能とする方針を
`AUTH_STRATEGY_DESIGN.md`のまま維持し、Firestore Security Rulesで直接書き込みを禁止する。

`spotComments`/`brightnessSpots`/`shadeSpots`/`announcements`はproject-039の名前空間のまま移植する
（chikaba_koreの`facilities`/`reviews`と衝突しないため、リネーム不要）。

### 6. モデレーション基盤の展開（将来検討）

chikaba_kore側は既に`reviews`にレート制限・通報・承認フローを導入済み（Phase 1）。
`spotComments`等への同基盤の展開はPhase 3の必須要件とはしないが、移植時に
`onReviewCreate`相当の関数を`onSpotCommentCreate`として複製しやすい構造になっている点は留意する。

## 段階的移行ステップ（Phase 3のサブフェーズ）

- [x] **Phase 3a**: `lib/models/`, `lib/services/`, `lib/firebase/`のコード移植（依存の少ない順）。
  匿名認証前提の`auth_service.dart`本体・`location_service.dart`・`subscription_service.dart`は
  既にchikaba_kore側で統一済みのため移植対象から除外。`map_projection.dart`（模式図描画）・
  `push_notification_service.dart`（既存NotificationServiceで代替済み）・
  `onboarding_storage.dart`/`notification_preference_storage.dart`（既存Hiveベース実装で代替）・
  `app_version.dart`（強制アップデート機能、対象外）も除外。
  project-039の`AuthService`（匿名サインイン前提）に依存していたFirebase実装層は、
  chikaba_kore側`AuthService`に`ensureSignedIn()`を追加する形で橋渡しした
- [x] **Phase 3b**: `MapCameraController`/`MapBaseOptions`/`comfortScoreColor`を`lib/views/widgets/map/`に実装し、
  既存の施設探索モード（`MapScreen`）をこれらの共通レイヤー経由に書き換え済み（`MAP_COMPONENT_INTEGRATION_DESIGN.md`の実装フェーズ）
- [x] **Phase 3c**: 地図タブへの`ModeSwitcher`（`SegmentedButton`）実装、安全ルートモードの地図描画統合。
  `safetyRouteProvider`で現在地周辺の安心ルートを検索し、`comfortScoreColor`で色分けした
  `Polyline`として描画。目的地選択・投稿・コメント・お知らせ・本人確認等の周辺機能はサブフェーズ3dへ
- [x] **Phase 3d**: 周辺機能（投稿確認/コメント/塗って投稿/本人確認）の画面移植・ルート追加。
  「塗って投稿」はproject-039の模式図キャンバス（`MapProjection`）方式ではなく、
  実際のGoogleMap上でなぞる方式に再設計（ユーザー確認済み、`docs/MAP_COMPONENT_INTEGRATION_DESIGN.md`の
  「実地図のみ」方針を維持）。`/safety-route/spots`・`/safety-route/comments`は地図タブの
  安全ルートモードのAppBarアクションから、`/safety-route/submit`はFABから、
  `/safety-route/verification`はマイページの「本人確認」セクションから遷移。
  `firestore.rules`/`firestore.indexes.json`に`shadeSpots`/`brightnessSpots`/`spotComments`用の
  ルール・インデックスを追加。お知らせ機能は方針通り先送り
- [x] **Phase 3e**: Firestoreスキーマ統合（`users`フィールド追加）・Security Rules統合。
  Phase 3dの`firestore.rules`更新で大部分は完了済み。整理の過程で
  `isValidUserCreate()`が`isPremium`同様に`isVerified`のガードを持っていなかった
  抜け穴（クライアントが作成時に`isVerified: true`を自称できてしまう）を発見・修正した。
  Cloud Functions（`syncVerificationStatus`/`handleSpotCreated`/`onSpotCommentCreated`/`voteSpot`等）
  自体の移植は本サブフェーズのスコープ外（クライアント側は常に`status/moderationStatus: 'pending'`で
  作成する設計のため、Cloud Functions未移植の間は投稿が承認待ちのまま残るだけで安全に停止する。
  実際に「即時反映」や「本人確認」を機能させるには別途Cloud Functions移植が必要。次のアクション参照）
- **Phase 3f**: project-039リポジトリの開発終了（アーカイブ）、chikaba_kore単一リポジトリでの運用開始。
  以下の順で実施する想定:
  1. Cloud Functions移植（Phase 3eで先送りした分）を完了し、実機でひととおり動作確認する
  2. project-039のREADMEに「chikaba_kore（近場まっぷ）に統合済み」と明記し、GitHub Actions（CI/CD）を無効化する
  3. リポジトリをアーカイブ（読み取り専用化）する。実施タイミングはユーザー判断（未決定の論点1）

各サブフェーズは独立してPR化・マージ可能な粒度を意図している。

## 次のアクション（Phase 3f着手前に必要）

- [ ] **Cloud Functions移植** — project-039の`functions/`から以下をchikaba_koreの`functions/`へ移植する必要がある。
  未移植の間は「塗って投稿」等の投稿が常に承認待ち（`pending`）のまま残り、実際には反映されない
  （安全側に停止するだけで、クラッシュ等の実害はない）:
  - `syncVerificationStatus`（電話番号認証確定→`users/{uid}.isVerified`・Custom Claim更新）
  - `handleSpotCreated`相当（`shadeSpots`/`brightnessSpots`の自動承認/承認待ち判定）
  - `onSpotCommentCreated`相当（NGワードフィルタ判定）
  - `voteSpot`（確認投票／通報の集計、自演・二重投票防止）

## 未決定の論点

1. **project-039リポジトリの扱い** — Phase 3f完了後にアーカイブするか、しばらく並行して残すか（Cloud Functions移植・実機確認が完了するまでは判断不要）
2. **「安全ルート」モードのブランディング** — chikaba_map内での名称・アイコン・配色（あんしんみちのテーマカラーを引き継ぐか、近場まっぷのテーマに合わせるか）
3. **お知らせ機能の扱い** — ✅ 方針決定済み。Phase 3では先送り、Phase 4候補として据え置き
4. **スポット投稿系へのモデレーション基盤展開の時期** — ✅ 方針決定済み。Phase 3内では対応せず、Phase 4に回す
