# 近場コレ (Chikaba Kore)

**「近場で、コレ。」** — 地元民と訪問者が「いま、この場所で」出会える施設発見プラットフォーム

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

## 📱 アプリ概要

**近場コレ** は、地元民と訪問者が「いま、この場所で」出会える施設発見プラットフォームです。

### 🎯 特徴

- **距離ベース発見** — 現在地から近い施設をすぐ見つける
- **リアルなレビュー** — 地元民と訪問者による正直なクチコミ
- **地元民バッジ** — 信頼できる情報源を視覚的に識別
- **穴場スコア** — 独自アルゴリズムで隠れた名店を発見
- **マルチエリア対応** — 17都市以上をサポート

### 📊 実装完了機能

- ✅ テキスト・カテゴリ検索
- ✅ クチコミ投稿・表示（最大3枚の画像対応）
- ✅ お気に入り管理（「行きたい」「今行く」タグ）
- ✅ プロフィール編集・画像アップロード
- ✅ Google Maps 統合
- ✅ Firebase 認証（メール・Google Sign-In）
- ✅ プッシュ通知設定
- ✅ プレミアム会員機能（¥100/月）

## 🚀 クイックスタート

### 必要な環境

- Flutter 3.x 以上
- Dart 3.0 以上
- Android SDK 21 以上（Android ビルド用）
- Xcode 14 以上（iOS ビルド用）

### インストール

```bash
# リポジトリをクローン
git clone https://github.com/zka32101/chikaba_kore.git
cd chikaba_kore

# 依存関係をインストール
flutter pub get

# アプリを起動（iOS/Android）
flutter run
```

### 環境設定

1. **Firebase プロジェクト** を作成
2. **Google Maps API キー** を取得
3. `.env` ファイルを作成：
   ```
   FIREBASE_PROJECT_ID=your_project_id
   GOOGLE_MAPS_API_KEY=your_api_key
   ```

## 📦 ビルド

### Android (APK)

```bash
# デバッグビルド
flutter build apk --debug

# リリースビルド
flutter build apk --release
```

### iOS

**前提条件:**
- Xcode 14 以上がインストール済み
- iOS 11.0 以上をターゲット
- Apple Developer アカウント（リリースビルド用）

```bash
# iOSプロジェクトの設定を確認
cd ios
pod repo update
cd ..

# デバッグビルド（シミュレーター向け）
flutter build ios --debug

# デバッグビルド（実機向け）
flutter build ios --debug --device-id <device_id>

# リリースビルド（App Store配布用）
flutter build ios --release

# IPAファイルを生成
flutter build ios --release --verbose
# ビルド済みアプリはbuild/ios/Release-iphoneos/に出力されます
```

**トラブルシューティング:**
```bash
# CocoaPodsの依存関係をクリア
cd ios
rm -rf Pods
rm Podfile.lock
pod install --repo-update
cd ..

# キャッシュをクリア
flutter clean
flutter pub get
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

## 🚀 自動ビルド・CI/CD

### GitHub Actions による自動ビルド・デプロイ

このプロジェクトは GitHub Actions による自動ビルド・デプロイパイプラインに対応しています。

**詳細ガイド**: [`yourwish/docs/build-ci-cd-guide.md`](https://github.com/zka32101/yourwish/blob/master/docs/build-ci-cd-guide.md)

#### トリガー条件
- ✅ `claude/**` ブランチへの push
- ✅ Pull Request (main/develop)
- ✅ 手動実行 (workflow_dispatch)
- ✅ 週1回スケジュール実行

#### 自動実行内容
1. **コード分析・テスト** - `flutter analyze`, `flutter test`
2. **Android ビルド** - APK/AAB 生成
3. **iOS ビルド** - IPA 生成 (unsigned)
4. **ビルドサマリー** - 結果集計

#### ワークフローファイル
- `.github/workflows/build-apk.yml` - 基本ビルド
- テンプレート: [`yourwish/.github/workflows/build-template.yml`](https://github.com/zka32101/yourwish/blob/master/.github/workflows/build-template.yml)

---

### 💻 ローカルビルド

#### APK生成（Android）
```bash
flutter build apk --release
```

#### iOS IPA生成
```bash
flutter build ios --release
```

#### Web リリースビルド
```bash
flutter build web --release
```

---

### 📚 SessionStart Hook（自動初期化）

Claude Code セッション起動時に自動的に以下を実行：
- `flutter pub get` - 依存関係インストール
- `flutter analyze` - コード分析

設定ファイル: `.claude/hooks/session-start.sh`

---

### 🧪 build-and-test スキル（6観点テスト）

```bash
/build-and-test chikaba_kore
```

**テスト観点**:
1. 起動テスト
2. 接続テスト
3. 課金画面
4. 認証フロー
5. 広告表示
6. クラッシュ検出

## 📁 プロジェクト構成

```
lib/
  ├── config/          # アプリ設定・ルーティング
  ├── models/          # データモデル
  ├── providers/       # Riverpod プロバイダー
  ├── repositories/    # データリポジトリ
  ├── services/        # Firebase・API・位置情報サービス
  ├── view_models/     # ビューモデル
  └── views/           # UI スクリーン・ウィジェット

test/                  # テストファイル
```

## 🧪 テスト実行

```bash
# すべてのテストを実行
flutter test

# カバレッジを含む
flutter test --coverage
```

## 📚 ドキュメント

- [アプリコンセプト](APP_CONCEPT_AND_FEATURES.md) — 全機能一覧
- [ロードマップ](FEATURE_INNOVATION_ROADMAP.md) — 今後の機能計画
- [プライバシーポリシー](release-outputs/policies/PRIVACY_POLICY.md)
- [セキュリティポリシー](release-outputs/policies/SECURITY_POLICY.md)

## 🤝 貢献

バグ報告・機能リクエストは [Issues](https://github.com/zka32101/chikaba_kore/issues) にお願いします。

プルリクエストを送信する前に、[CONTRIBUTING.md](CONTRIBUTING.md) をご覧ください。

## 📄 ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。詳細は [LICENSE](LICENSE) をご覧ください。

## 👥 開発者

- **PetitWorksApps** — 開発・メンテナンス

## 📞 サポート

問題が発生した場合は、[GitHub Issues](https://github.com/zka32101/chikaba_kore/issues) でお知らせください。

---

**更新日**: 2026年9月
**バージョン**: 1.0.0
