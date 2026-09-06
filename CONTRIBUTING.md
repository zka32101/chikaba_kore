# 貢献ガイドライン

このプロジェクトへの貢献をご検討いただきありがとうございます！以下のガイドラインに従ってください。

## 📋 目次

- [開発環境のセットアップ](#開発環境のセットアップ)
- [ブランチ戦略](#ブランチ戦略)
- [コミットメッセージ](#コミットメッセージ)
- [コード品質](#コード品質)
- [プルリクエストプロセス](#プルリクエストプロセス)
- [テスト](#テスト)
- [ドキュメント](#ドキュメント)
- [行動規範](#行動規範)

## 開発環境のセットアップ

### 必須ツール

- **Flutter 3.x 以上** — [インストール手順](https://flutter.dev/docs/get-started/install)
- **Dart 3.0 以上** — Flutterに同梱
- **Android SDK 21 以上** — Android開発用
- **Xcode 14 以上** — iOS開発用
- **Git** — バージョン管理

### 初期セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/zka32101/chikaba_kore.git
cd chikaba_kore

# 依存関係をインストール
flutter pub get

# 分析ツールを実行（推奨）
flutter analyze

# コード整形を確認
dart format lib test --line-length 100
```

### IDE設定

**VS Code:**
```bash
code .
# 拡張機能をインストール:
# - Flutter
# - Dart
# - Thunder Client (API テスト用)
```

**Android Studio / IntelliJ:**
```bash
# プラグインをインストール:
# - Flutter
# - Dart
# - Google Maps Platform
```

## ブランチ戦略

### ブランチ命名規則

```
feature/brief-description      # 新機能
bugfix/issue-description        # バグ修正
docs/update-description         # ドキュメント更新
refactor/area-improvement       # リファクタリング
chore/maintenance-task          # 保守作業
```

### ブランチの作成

```bash
# 最新のmainブランチから新しいブランチを作成
git fetch origin
git checkout -b feature/my-feature origin/main
```

## コミットメッセージ

### フォーマット

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 例

```
feat(auth): add Google Sign-In support

- Implement Google OAuth 2.0 integration
- Update auth service with Google provider
- Add sign-in button to login screen

Closes #123
```

### タイプ

- **feat** — 新機能
- **fix** — バグ修正
- **docs** — ドキュメント変更
- **style** — コード整形（機能に影響なし）
- **refactor** — コードリファクタリング
- **perf** — パフォーマンス改善
- **test** — テスト追加・修正
- **chore** — ビルドプロセスなどの変更

## コード品質

### 静的解析

```bash
# Dartアナライザを実行
flutter analyze

# 追加チェック（推奨）
dart analyze lib
```

### コード整形

```bash
# 指定ディレクトリをフォーマット
dart format lib test --line-length 100

# すべてのファイルをフォーマット
dart format .
```

### コーディング規約

1. **命名規則**
   - クラス: PascalCase （例: `UserProfile`）
   - メソッド/変数: camelCase （例: `getUserData`）
   - 定数: UPPER_SNAKE_CASE （例: `MAX_RETRY_COUNT`）

2. **Dartの慣例**
   - Effective Dartに従う: https://dart.dev/guides/language/effective-dart
   - 関数は3ネストまで（深すぎるネスティングを避ける）

3. **Flutterの慣例**
   - `const` コンストラクタを使用
   - `key` パラメータを適切に指定
   - Widget分割で可読性を向上

## プルリクエストプロセス

### 提出前チェックリスト

- [ ] ブランチが最新のmainから作成されている
- [ ] `flutter analyze`でエラーがない
- [ ] コードが`dart format`でフォーマットされている
- [ ] すべてのテストが通過している
- [ ] コミットメッセージが規約に従っている
- [ ] ドキュメントが更新されている（必要な場合）

### PR作成手順

```bash
# リモートにプッシュ
git push origin feature/my-feature

# GitHub上でPRを作成
# PR説明テンプレートに従って記入
```

### PR説明テンプレート

```markdown
## 説明
このPRは何をするのか簡潔に説明してください。

## 変更内容
- 変更1
- 変更2
- 変更3

## テスト方法
この変更をテストする方法を説明してください。

## スクリーンショット
UI変更がある場合は含めてください。

## 関連Issues
Closes #123, #456
```

### レビュープロセス

1. **自動チェック**
   - CI/CD パイプラインが実行される
   - コード品質チェック（lint, format）
   - テスト実行

2. **コードレビュー**
   - 最低1人以上のレビューアによる承認が必要
   - すべてのコメントに対応する
   - 修正後は再レビューをリクエスト

3. **マージ**
   - すべてのチェックが通過
   - レビューアの承認を取得
   - Squashコミットでマージ

## テスト

### テスト実行

```bash
# すべてのテストを実行
flutter test

# カバレッジレポート付きで実行
flutter test --coverage

# 特定のテストファイルを実行
flutter test test/models/user_model_test.dart

# ウォッチモード（ファイル変更時に自動実行）
flutter test --watch
```

### テストの種類

1. **ユニットテスト**
   - 単一の関数やクラスをテスト
   - 場所: `test/`

2. **ウィジェットテスト**
   - UIコンポーネント単体をテスト
   - 場所: `test/`

3. **統合テスト**
   - 複数のコンポーネント間の相互作用をテスト
   - 場所: `integration_test/`

### テストカバレッジ

```bash
# カバレッジレポートを生成
flutter test --coverage

# HTMLレポートを表示（オプション）
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## ドキュメント

### README更新

- 新しい機能やAPIはREADME.mdに追記
- スクリーンショットやビデオで動作を説明
- セットアップ手順の変更は明確に記述

### インラインコメント

```dart
/// この関数は何をするのか簡潔に説明
/// 
/// より詳細な説明が必要な場合はここに記述
/// 複数行の説明も可能
/// 
/// ```dart
/// var result = complexFunction(value);
/// ```
/// 
/// Returns: 戻り値の説明
/// Throws: 例外がある場合は記述
String complexFunction(String value) {
  // 実装
}
```

### APIドキュメント

- Dartdocコメントを使用（`///`）
- パブリックメソッドにはすべてドキュメントを追加
- 複雑なロジックは説明コメントを追加

```bash
# ドキュメント生成（オプション）
dart doc
```

## 行動規範

### 期待される行動

- 他の貢献者を尊重する
- 建設的で親切なコミュニケーション
- 異なる意見や経験を大切にする

### 受け入れられない行為

- ハラスメント、差別、暴力的な言葉
- プライベート情報の共有
- スパムやプロモーション

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。
貢献することで、あなたの貢献もMITライセンスの対象になることに同意します。

## サポート

質問や問題がある場合は、以下の方法でお問い合わせください：

1. **GitHub Issues** — バグ報告や機能リクエスト
2. **Discussions** — 一般的な質問や提案
3. **Email** — 機密事項の報告

---

貢献してくれてありがとうございます！🙏

