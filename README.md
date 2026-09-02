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

```bash
# デバッグビルド
flutter build ios --debug

# リリースビルド
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

## 🔄 CI/CD パイプライン

### 自動ワークフロー

- **Test** (`test.yml`) — ユニット・ウィジェットテスト実行
- **Lint** (`lint.yml`) — 静的解析・コード品質チェック
- **Deploy** (`deploy.yml`) — リリースビルド・GitHub Releases へのアップロード

### リリース方法

```bash
# タグを作成してプッシュ（自動的にビルド・デプロイ）
git tag v1.0.0
git push origin v1.0.0
```

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
