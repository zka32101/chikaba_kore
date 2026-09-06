# セキュリティポリシー

**最終更新**: 2026年9月
**バージョン**: 1.0.0

## 目次

- [概要](#概要)
- [脆弱性報告](#脆弱性報告)
- [セキュア開発実践](#セキュア開発実践)
- [データ保護](#データ保護)
- [認証とアクセス制御](#認証とアクセス制御)
- [依存関係管理](#依存関係管理)
- [インシデント対応](#インシデント対応)
- [セキュリティ更新](#セキュリティ更新)

## 概要

近場コレは、ユーザーのプライバシーとデータセキュリティを最優先に考えています。このドキュメントは、アプリケーションのセキュリティについて、報告手順とベストプラクティスを説明します。

## 脆弱性報告

### セキュリティ問題の報告

セキュリティ上の問題を発見された場合は、**公開ではなく非公開で報告してください**。

**報告方法:**

1. **Email**: security@chikaba-kore.app (公開前報告用)
   - 件名: `Security Issue: [Brief Description]`
   - 脆弱性の詳細説明
   - 影響範囲
   - 再現方法（可能な場合）
   - 修正案（あれば）

2. **GitHub Security Advisory**: 
   - リポジトリの "Security" タブから報告
   - https://github.com/zka32101/chikaba_kore/security

### 報告後の流れ

1. **確認** (48時間以内)
   - セキュリティチームが報告を確認
   - 受け取り確認メールを送付

2. **評価** (1-5日)
   - 脆弱性の重大度を評価
   - 影響范囲を分析

3. **修正開発** (進行中)
   - パッチ開発を開始
   - テスト環境で検証

4. **リリース**
   - 緊急セキュリティパッチをリリース
   - セキュリティアドバイザリを発行

5. **クレジット**
   - 報告者にクレジットを付与（希望に応じて）
   - セキュリティアドバイザリにお名前を記載

## セキュア開発実践

### コード審査

- すべてのプルリクエストにセキュリティレビューを実施
- 暗号化、認証、入力検証に関する変更は特に厳しくレビュー
- 依存関係の更新時は脆弱性スキャンを実施

### 静的コード分析

```bash
# Dartアナライザで潜在的な問題を検出
flutter analyze

# 追加のセキュリティチェック
dart analyze lib --fatal-infos
```

### 依存関係スキャン

```bash
# Pubパッケージの既知の脆弱性をチェック
flutter pub outdated
flutter pub upgrade
```

## データ保護

### 転送中のデータ

- **TLS 1.2以上** — すべてのネットワーク通信を暗号化
- **証明書ピニング** — Firebase通信で実装
- **HTTPS強制** — すべてのAPIは暗号化されたチャネル経由

### 保存データ

#### ローカルストレージ

```dart
// 暗号化されたローカルストレージ
final secureStorage = FlutterSecureStorage();
await secureStorage.write(key: 'token', value: encryptedToken);
```

**Android:**
- Android Keystore を使用
- 暗号化キーはシステムレベルで保護

**iOS:**
- Keychain を使用
- セキュアエンクレーブで保護

#### クラウドストレージ

- **Firebase Firestore**: 保存時自動暗号化
- **Firebase Storage**: Google管理キーで暗号化
- **バックアップ**: エンドツーエンド暗号化

### 機密データの取り扱い

**ログに出力してはいけないデータ:**
- 認証トークン
- パスワード / PIN
- API キー
- クレジットカード情報
- 個人識別情報 (PII)

```dart
// ❌ 悪い例
print('Token: $authToken'); // トークンをログに出力

// ✅ 良い例
print('Token: ${authToken.substring(0, 4)}...'); // マスク処理
```

## 認証とアクセス制御

### 認証方法

1. **メール/パスワード認証**
   - Firebase Authentication を使用
   - bcrypt でパスワードをハッシュ化
   - 最小8文字、大文字・小文字・数字を含む

2. **Google Sign-In**
   - OAuth 2.0 を使用
   - ID トークン検証で二重確認

3. **セッション管理**
   - JWT トークン（Firebase ID Token）
   - トークン有効期間: 1時間
   - リフレッシュトークン: 長期有効

### パーミッション管理

```yaml
# Android
android/app/src/main/AndroidManifest.xml:
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

# iOS
ios/Runner/Info.plist:
  NSLocationWhenInUseUsageDescription
  NSCameraUsageDescription
  NSPhotoLibraryUsageDescription
```

### パーミッション要求

```dart
// ユーザーが明示的に許可した場合のみパーミッションを使用
if (await Permission.location.request().isGranted) {
  // 位置情報を取得
}
```

## 依存関係管理

### パッケージの審査

新しいパッケージを追加する前に:

1. **Pub.dev で評価を確認**
   - 人気度 (popularity score)
   - メンテナンス状況
   - セキュリティ履歴

2. **リポジトリをチェック**
   - ソースコード
   - 最後の更新日時
   - Issue / PR アクティビティ

3. **ライセンス確認**
   - MIT, Apache 2.0 など許可的なライセンスか
   - GPL など制限的なライセンスはないか

### 既知の脆弱性

```bash
# 定期的にスキャン
flutter pub outdated

# アップグレード可能なパッケージを更新
flutter pub upgrade

# 特定パッケージをアップグレード
flutter pub upgrade path_provider
```

### ロック方式

```bash
# pubspec.lock を必ずコミット
git add pubspec.lock
git commit -m "deps: update dependencies"

# 本番環境でのみ固定バージョンを使用
flutter pub get --offline
```

## インシデント対応

### セキュリティインシデントの定義

- 未認可のデータアクセス
- データ侵害
- サービス停止 (DoS)
- 暗号化キーの漏洩
- 認証システムの破綻

### 対応手順

1. **検出と評価** (30分以内)
   - インシデントの性質を評価
   - 影響を受けたユーザー数を確認
   - 深刻度レベルを決定

2. **封じ込め** (1時間以内)
   - 侵害を停止させる
   - ロールバック (必要に応じて)
   - サーバー側で制御

3. **通知** (24時間以内)
   - 影響を受けたユーザーに通知
   - GitHub Security Advisory を発行
   - メディア対応

4. **根本原因分析** (3日以内)
   - 詳細な調査実施
   - 再発防止策を検討

5. **復旧と改善**
   - セキュリティパッチリリース
   - インフラ改善
   - ドキュメント更新

## セキュリティ更新

### パッチリリース方針

脆弱性の深刻度:

| 深刻度 | 例 | リリース目安 |
|-------|-----|-----------|
| **Critical** | リモートコード実行 | 24時間以内 |
| **High** | 認証回避、データ漏洩 | 3日以内 |
| **Medium** | 入力検証不足 | 1週間以内 |
| **Low** | 情報開示 | 次期リリース |

### アップデート案内

セキュリティアップデートがある場合:

1. **アプリ内通知** — 更新が利用可能なことを通知
2. **自動更新** — Google Play / App Store で自動更新を推奨
3. **強制更新** — Critical 脆弱性の場合のみ

## コンプライアンス

### 適用される規制

- **GDPR** — ヨーロッパのユーザーデータ
- **CCPA** — カリフォルニアのユーザーデータ
- **個人情報保護方針法** — 日本のユーザーデータ

詳細は [プライバシーポリシー](./PRIVACY_POLICY.md) を参照してください。

## サポート

セキュリティに関する質問:

- **脆弱性報告**: security@chikaba-kore.app
- **一般的な質問**: support@chikaba-kore.app
- **GitHub Issues**: セキュリティ関連ではない場合のみ

---

このセキュリティポリシーは定期的に見直されます。
最終更新: 2026年9月
