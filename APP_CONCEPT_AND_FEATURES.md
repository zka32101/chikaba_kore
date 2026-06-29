# 近場コレ (Chikaba Kore) - アプリコンセプト・機能一覧

**バージョン**: 1.0.0  
**リリース予定**: 2026年6月  
**プラットフォーム**: Android, iOS  
**開発環境**: Flutter 3.11.5+, Dart 3.0+

---

## 📱 アプリコンセプト

**「近場で、コレ。」** — 地元民と訪問者が「いま、この場所で」出会える施設発見プラットフォーム

### ターゲットユーザー

- **地元民** (Local): 地域に住んでいる、地域をよく知っているユーザー
  - 地元の隠れた名店・穴場スポットを発見・共有
  - 新着スポット情報を素早くキャッチ
  
- **訪問者** (Visitor): 旅行・観光・出張で訪れたユーザー
  - 目的地周辺のリアルな施設情報を検索
  - 地元民のクチコミを参考に安心して利用

### コア価値

1. **距離ベース発見** — 現在地から近い施設をすぐ見つける
2. **リアルなレビュー** — 地元民と訪問者による正直なクチコミ
3. **都市ごとのローカルコミュニティ** — 複数都市対応で全国利用可能
4. **かんたん共有** — 見つけた施設やお気に入りをシェア

---

## ✨ 実装完了機能

### 🔍 発見・検索機能

| 機能 | 詳細 | ステータス |
|------|------|----------|
| **テキスト検索** | 施設名・住所・キーワードで検索 | ✅ 完了 |
| **カテゴリフィルタ** | レストラン、カフェ、公園など17カテゴリ | ✅ 完了 |
| **評価フィルタ** | ★3以上、★4以上、★4.5以上で絞り込み | ✅ 完了 |
| **営業中フィルタ** | 営業中の施設のみ表示 | ✅ 完了 |
| **距離表示** | Haversine 計算で現在地から距離を表示 | ✅ 完了 |
| **検索結果ソート** | デフォルト/評価順/新着順でソート | ✅ 完了 |
| **検索履歴** | Hive キャッシュで最大10件保存 | ✅ 完了 |
| **複数都市対応** | 「すべてのエリア」と「選択中のエリア」を切り替え | ✅ 完了 |
| **マップ統合** | Google Maps で施設ピン表示・テキスト検索 | ✅ 完了 |

### ⭐ レビュー・クチコミ機能

| 機能 | 詳細 | ステータス |
|------|------|----------|
| **クチコミ投稿** | ★1-5、テキスト、写真（最大3枚）で投稿 | ✅ 完了 |
| **クチコミ表示** | ユーザープロフィール、地元民/訪問者バッジ付き | ✅ 完了 |
| **画像拡大表示** | クチコミ画像をタップで フルスクリーン表示 | ✅ 完了 |
| **クチコミペーベーション** | 5件ずつ「もっと読む」で表示 | ✅ 完了 |
| **クチコミフィルタ** | ★3以上、★4以上で絞り込み | ✅ 完了 |
| **クチコミソート** | 新着順/高評価順/低評価順 | ✅ 完了 |

### 💝 お気に入り機能

| 機能 | 詳細 | ステータス |
|------|------|----------|
| **「行きたい」タグ** | 後で行く予定の施設を保存 | ✅ 完了 |
| **「今行く」タグ** | 現在向かっている施設を標記 | ✅ 完了 |
| **メモ保存** | 個人用メモを各施設に添付 | ✅ 完了 |
| **クチコミ数表示** | 各お気に入り施設のレビュー数表示 | ✅ 完了 |
| **お気に入り共有** | Share で施設リストをシェア | ✅ 完了 |
| **ソート機能** | 保存日順/名前順/カテゴリ順でソート | ✅ 完了 |
| **比較機能** | 複数施設を選択・比較表示（基本実装） | ✅ 完了 |

### 👤 ユーザー管理・認証

| 機能 | 詳細 | ステータス |
|------|------|----------|
| **メール登録** | メール + パスワードで新規登録 | ✅ 完了 |
| **メールログイン** | 登録したメール/パスワードでログイン | ✅ 完了 |
| **Google ログイン** | Google Sign-In で簡単ログイン | ✅ 完了 |
| **パスワードリセット** | 登録メールにリセットリンクを送信 | ✅ 完了 |
| **認証エラー処理** | Firebase エラーを日本語メッセージに変換 | ✅ 完了 |

### 🎨 プロフィール・設定

| 機能 | 詳細 | ステータス |
|------|------|----------|
| **プロフィール編集** | ニックネーム、プロフィール画像を編集 | ✅ 完了 |
| **画像アップロード** | Firebase Storage に写真をアップロード | ✅ 完了 |
| **エリア選択** | 都市を17種類から選択（プロフィール反映） | ✅ 完了 |
| **ユーザータイプ** | 地元民 / 訪問者 を選択 | ✅ 完了 |
| **統計ダッシュボード** | 投稿数、お気に入り数、訪問施設数を表示 | ✅ 完了 |
| **アカウント削除** | 確認ダイアログ後、全データを削除 | ✅ 完了 |
| **プレミアム会員** | ¥100/月でプレミアムにアップグレード可能 | ✅ 完了 |
| **プッシュ通知設定** | 新着スポット・お知らせ通知を ON/OFF | ✅ 完了 |

### 🏠 ホーム画面

| 機能 | 詳細 | ステータス |
|------|------|----------|
| **フィードビュー** | リール（縦スクロール）/ グリッド（2列）の切り替え | ✅ 完了 |
| **カテゴリバー** | 17カテゴリから選択（スクロール可） | ✅ 完了 |
| **評価フィルタバー** | ★3以上、★4以上、★4.5以上 | ✅ 完了 |
| **営業中フィルタ** | ボタンで営業中のみ表示 ON/OFF | ✅ 完了 |
| **都市切り替え** | AppBar で「📍 選択中のエリア」←→「🌍 全エリア」 | ✅ 完了 |
| **無限スクロール** | スクロール時に自動読み込み（ページネーション） | ✅ 完了 |

### 🗺️ マップ機能

| 機能 | 詳細 | ステータス |
|------|------|----------|
| **Google Maps 統合** | 全施設をマップ上にピン表示 | ✅ 完了 |
| **マップ検索** | マップ上でテキスト検索、フローティング検索バー | ✅ 完了 |
| **ピンタップ** | ピンをタップで施設詳細へ遷移 | ✅ 完了 |
| **カテゴリフィルタ** | マップ上の表示施設をカテゴリで絞り込み | ✅ 完了 |

### 📋 施設詳細画面

| 機能 | 詳細 | ステータス |
|------|------|----------|
| **施設情報表示** | 名前、アドレス、電話、営業時間、ウェブサイト | ✅ 完了 |
| **画像ギャラリー** | 複数写真をスワイプ表示 | ✅ 完了 |
| **フルスクリーン表示** | 画像をタップで フルスクリーン、ピンチズーム対応 | ✅ 完了 |
| **お気に入りボタン** | ハートアイコンで「行きたい」「今行く」を切り替え | ✅ 完了 |
| **シェアボタン** | Google Maps リンク付きで施設情報を共有 | ✅ 完了 |
| **クチコミセクション** | 総件数・評価フィルタ・ソート機能付き | ✅ 完了 |
| **クチコミ投稿ボタン** | ログイン済みなら「クチコミを書く」ボタン表示 | ✅ 完了 |
| **営業時間表示** | 月～日の営業時間を表形式で表示 | ✅ 完了 |

### 🎯 品質・インフラ

| 機能 | 詳細 | ステータス |
|------|------|----------|
| **Riverpod 状態管理** | StateNotifier + autoDispose で効率的に管理 | ✅ 完了 |
| **go_router ナビゲーション** | 深いリンク対応、パラメータ型安全 | ✅ 完了 |
| **Firebase Firestore** | 施設・レビュー・ユーザーデータ永続化 | ✅ 完了 |
| **Firebase Storage** | プロフィール画像・レビュー写真アップロード | ✅ 完了 |
| **Firebase Auth** | メール/Google ログイン、セッション管理 | ✅ 完了 |
| **Firebase Messaging** | プッシュ通知送信（ローカル + リモート） | ✅ 完了 |
| **Hive ローカルキャッシュ** | 検索履歴、オンボーディングフラグ、通知設定 | ✅ 完了 |
| **キャッシュされた画像** | `cached_network_image` で高速表示 | ✅ 完了 |
| **Material 3 デザイン** | リップルエフェクト、トランジション、カラーシステム | ✅ 完了 |
| **ローカライゼーション** | すべてのテキストが日本語対応 | ✅ 完了 |
| **エラー処理** | Firebase エラーを日本語メッセージに変換 | ✅ 完了 |

---

## 🛠️ 技術スタック

### フロントエンド
- **Flutter**: 3.11.5+
- **Dart**: 3.0+
- **状態管理**: Riverpod (flutter_riverpod 2.6.1)
- **ナビゲーション**: go_router 14.x
- **UI/UX**: Material 3, cupertino_icons

### バックエンド・インフラ
- **認証**: Firebase Authentication
- **データベース**: Cloud Firestore
- **ストレージ**: Firebase Storage
- **プッシュ通知**: Firebase Cloud Messaging + local_notifications
- **分析**: Firebase Analytics, Crashlytics（オプション）
- **ローカルストレージ**: Hive (hive_flutter)

### 外部ライブラリ
- **マップ**: google_maps_flutter
- **位置情報**: geolocator (Haversine 計算)
- **画像処理**: cached_network_image, image_picker
- **URL**: url_launcher, go_router
- **シェア**: share_plus
- **その他**: intl (日付フォーマット), shimmer (ローディング)

---

## 📊 アーキテクチャ

### ファイル構成
```
lib/
├── main.dart                          # エントリポイント
├── config/
│   ├── router.dart                    # go_router 定義
│   └── theme/
│       └── app_theme.dart             # Material 3 テーマ
├── models/                            # Firestore スキーマ
│   ├── user_model.dart
│   ├── facility_model.dart
│   ├── review_model.dart
│   ├── favorite_model.dart
│   └── ...
├── services/                          # Firestore/Auth ロジック
│   ├── auth_service.dart
│   ├── facility_service.dart
│   ├── firestore_service.dart
│   ├── storage_service.dart
│   ├── cache_service.dart
│   ├── location_service.dart
│   └── notification_service.dart
├── repositories/                      # Service ラッパー
│   ├── auth_repository.dart
│   ├── facility_repository.dart
│   ├── review_repository.dart
│   └── favorite_repository.dart
├── providers/                         # Riverpod Provider
│   ├── auth_provider.dart
│   ├── facility_provider.dart
│   ├── favorite_provider.dart
│   ├── location_provider.dart
│   └── ...
├── view_models/                       # StateNotifier
│   ├── home_view_model.dart
│   ├── search_view_model.dart
│   ├── facility_detail_view_model.dart
│   ├── write_review_view_model.dart
│   └── ...
├── views/                             # UI
│   ├── splash_screen.dart
│   ├── auth/
│   ├── main_tabs/
│   │   ├── home_screen.dart
│   │   ├── map_screen.dart
│   │   ├── favorite_screen.dart
│   │   ├── settings_screen.dart
│   │   └── ...
│   ├── facility_detail_screen.dart
│   ├── search_screen.dart
│   ├── profile_edit_screen.dart
│   ├── write_review_screen.dart
│   ├── fullscreen_image_screen.dart
│   ├── onboarding_screen.dart
│   └── widgets/
│       ├── custom_app_bar.dart
│       ├── facility_card.dart
│       ├── review_item.dart
│       └── ...
└── utils/
    ├── constants.dart
    ├── extensions.dart
    ├── validators.dart
    ├── auth_error.dart
    └── logger.dart
```

### 状態管理パターン
- **Global State**: `authNotifierProvider`, `favoritesProvider` など
- **Local State**: ページ内の TabIndex, TextEditingController など
- **Cached State**: `currentLocationProvider`, `currentUserProvider` など

---

## 🚀 リリース情報

### ビルドArtifacts
- **Android APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **Android AAB**: `build/app/outputs/bundle/release/app-release.aab`
- **iOS IPA**: `build/ios/iphoneos/Runner.app`

### リリースチェックリスト
- [ ] Google Play Console でアプリを新規作成
- [ ] `minSdk` と `targetSdk` を確認 (minSdk: 21, targetSdk: 34)
- [ ] `package name` を確認 (com.petitStudio.chikabaKore)
- [ ] Google Play ストアの説明文・スクリーンショット・プライバシーポリシー を登録
- [ ] App Store Connect でアプリを新規作成
- [ ] Bundle ID を確認
- [ ] プライバシーポリシー、スクリーンショット、 App Preview を登録
- [ ] Firebase Console で Google Play/Apple Store 連携を設定
- [ ] Crashlytics ダッシュボードを確認
- [ ] ベータ版リリース（Google Play internal testing, App Store TestFlight）
- [ ] フィードバック収集 → 修正
- [ ] 本番リリース

---

## 📝 ドキュメント

- **開発ガイド**: `docs/DEVELOPMENT.md`
- **ビルド手順**: `docs/BUILD.md`
- **API 仕様**: `docs/API.md`
- **テスト仕様**: `docs/TESTING.md`
- **セキュリティ**: `docs/SECURITY.md`

---

## 🔄 今後の拡張予定

### Phase 2
- [ ] ダークモード対応
- [ ] レビュー返信機能（オーナー向け）
- [ ] 施設チェックイン機能
- [ ] ウィジェット（ショートカット）
- [ ] オフラインモード（Hive キャッシュ拡張）

### Phase 3
- [ ] 複数言語対応（英語、中国語）
- [ ] ARナビゲーション
- [ ] ライブマップ（リアルタイム更新）
- [ ] ソーシャル機能（フォロー、フィード共有）
- [ ] 月次ランキング

---

## 📞 サポート・お問い合わせ

**開発者**: Petit Studio  
**メール**: zkaz83@gmail.com  
**プライバシーポリシー**: `https://chikaba-kore.com/privacy`  
**利用規約**: `https://chikaba-kore.com/terms`

---

**最終更新**: 2026-06-10  
**バージョン**: 1.0.0（リリース準備中）
