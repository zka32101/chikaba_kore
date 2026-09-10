# 自動ビルド・デプロイメントガイド
# Automated Build & Deployment Guide

このガイドは、GitHub Actions を用いた Flutter プロジェクトの自動ビルド・デプロイメント方法を説明します。

## 📋 概要 / Overview

**近場コレ (Chikaba Kore)** のデプロイメントパイプラインは、Git タグまたは手動トリガーで、複数プラットフォーム向けのリリースビルドを自動で生成します。

| Platform | Artifact | Status |
|----------|----------|--------|
| Android  | APK + AAB | ✅ Automated |
| iOS      | IPA + ZIP | ✅ Automated (artifact) |
| Web      | SPA      | ✅ Automated (artifact) |

---

## 🚀 ワークフロー実行方法 / Running the Workflow

### 方法 1: タグプッシュでトリガー (Automatic)

```bash
# バージョンタグをプッシュ
git tag v1.0.0
git push origin v1.0.0
```

タグが `v*` パターンにマッチすると、自動でワークフローが開始します。

### 方法 2: 手動トリガー (Manual)

GitHub Web UI の **Actions** タブで `Build and Deploy` ワークフローを選択し、**Run workflow** ボタンをクリック。

```bash
# CLI を使用する場合
gh workflow run deploy.yml
```

---

## 🔧 必須セットアップ / Required Setup

### 1. GitHub Secret: GOOGLE_SERVICES_JSON

Firebase の `google-services.json` を Base64 エンコードして保存：

```bash
# google-services.json をエンコード
base64 -i android/app/google-services.json

# 出力をコピーして、GitHub Settings > Secrets に GOOGLE_SERVICES_JSON として登録
```

**ワークフローでの使用:**
```yaml
- name: Restore google-services.json from Secret
  run: |
    echo "${{ secrets.GOOGLE_SERVICES_JSON }}" | base64 -d > android/app/google-services.json
```

### 2. Gradle メモリ設定 (Critical)

`android/gradle.properties` で Gradle JVM メモリを設定：

```properties
org.gradle.jvmargs=-Xmx2048m -XX:+UseSerialGC -XX:MaxMetaspaceSize=1024m
```

**設定の理由:**
- `-Xmx2048m`: ヒープメモリ 2GB (大規模な Firebase・Google Maps 依存関係向け)
- `-XX:MaxMetaspaceSize=1024m`: メタスペース 1GB (Kotlin 2.3.20 コード生成向け)
- `-XX:+UseSerialGC`: シングルスレッド GC (CI 環境での安定性)

**トラブルシューティング:**
- APK ビルドが ~5 分で失敗 → Metaspace OOM (メタスペース増やす)
- すぐに失敗 → Heap OOM (ヒープ増やす)

---

## 📦 ワークフロー構成 / Workflow Structure

### ファイル位置
`.github/workflows/deploy.yml`

### ジョブ構成

#### 1. **build-android** (Linux 環境)
- Flutter 依存関係取得
- google-services.json 復元
- gradle-wrapper.jar 自動生成
- リリース APK ビルド
- リリース AAB (App Bundle) ビルド
- GitHub Releases へ APK 発行

**重要:** gradle-wrapper.jar が存在しない場合、CI は自動生成。これにより CI 環境でも Gradle が動作。

#### 2. **build-ios** (macOS 環境)
- Flutter 依存関係取得
- リリース IPA ビルド (`--no-codesign`)
- ビルド成功時に ZIP 圧縮
- GitHub Artifacts へアップロード

**注:** コード署名はスキップ (証明書管理が必要な場合は別途設定)

#### 3. **build-web** (Linux 環境)
- Flutter Web ビルド (`--release`)
- ビルド成功時に GitHub Artifacts へアップロード

#### 4. **emulator-test** (Android 依存)
- build-android 成功後に実行
- Flutter ユニットテスト実行

---

## 🔄 ワークフローファイルの全体構造

```yaml
name: Build and Deploy

on:
  push:
    tags:
      - 'v*'              # v1.0.0 形式のタグで自動トリガー
  workflow_dispatch:      # 手動トリガー

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      # Flutter セットアップ
      # google-services.json 復元 (Secret から)
      # gradle-wrapper.jar 自動生成
      # APK ビルド
      # AAB ビルド
      # GitHub Releases へ APK 発行

  build-ios:
    runs-on: macos-latest
    steps:
      # Flutter セットアップ
      # IPA ビルド
      # Artifacts へアップロード

  build-web:
    runs-on: ubuntu-latest
    steps:
      # Flutter Web ビルド
      # Artifacts へアップロード

  emulator-test:
    needs: build-android
    steps:
      # Flutter テスト実行
```

---

## 📊 ビルド成功の確認 / Verifying Build Success

### GitHub Web UI で確認

1. **Actions** タブを開く
2. **Build and Deploy** ワークフローを選択
3. 最新の実行をクリック
4. 各ジョブのステータスを確認

### ステータス一覧

| Job | Success Sign | Artifact Location |
|-----|-------------|-------------------|
| build-android | ✅ all steps green | Releases > Assets (.apk) |
| build-ios | ✅ IPA ビルド完了 | Artifacts > ios-build |
| build-web | ✅ Web ビルド完了 | Artifacts > web-build |
| emulator-test | ✅ テスト成功 | - |

### リリースファイルのダウンロード

```bash
# GitHub CLI で最新リリースをダウンロード
gh release download $(gh release list --limit 1 --json tagName --jq '.[0].tagName')
```

---

## 🛠️ カスタマイズと拡張 / Customization

### Android ビルドオプション追加例

ワークフロー内の APK ビルドステップを修正：

```yaml
- name: Build release APK with obfuscation
  run: flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

### Web デプロイメント追加例

`build-web` ジョブ後に Firebase Hosting へデプロイ：

```yaml
- name: Deploy to Firebase Hosting
  uses: FirebaseExtended/action-hosting-deploy@v0
  with:
    repoToken: '${{ secrets.GITHUB_TOKEN }}'
    firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
    channelId: live
    projectId: chikaba-kore
```

### 通知設定追加例

ビルド失敗時に Slack へ通知：

```yaml
- name: Notify Slack on failure
  if: failure()
  uses: slackapi/slack-github-action@v1.24.0
  with:
    payload: |
      {
        "text": "APK Build Failed: ${{ job.status }}"
      }
```

---

## 🔐 セキュリティ考慮事項 / Security Notes

1. **Secret 管理**
   - `GOOGLE_SERVICES_JSON` は必ず GitHub Secret に登録
   - コード内にハードコードしない

2. **Gradle Wrapper JAR**
   - CI で自動生成される
   - リポジトリに commit しない場合、`.gitignore` に追加

3. **署名設定**
   - iOS: 本番リリースにはコード署名が必須 (CI では `--no-codesign`)
   - Android: リリースビルドは debug キーで署名 (本番は別途設定)

---

## 📚 他プロジェクトへの適用 / Applying to Other Projects

このセットアップを他の Flutter プロジェクトに適用する手順：

### ステップ 1: ワークフローファイルをコピー
```bash
cp .github/workflows/deploy.yml ../your_other_project/.github/workflows/
```

### ステップ 2: Gradle メモリ設定を同期
```bash
# android/gradle.properties を以下で更新
org.gradle.jvmargs=-Xmx2048m -XX:+UseSerialGC -XX:MaxMetaspaceSize=1024m
```

### ステップ 3: Secret を登録
新規プロジェクトの GitHub Settings で `GOOGLE_SERVICES_JSON` を設定。

### ステップ 4: Flutter バージョン確認
`pubspec.yaml` の `flutter:` セクションと `.github/workflows/deploy.yml` の `flutter-version` を一致させる。

```yaml
# .github/workflows/deploy.yml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.47.2'  # pubspec.yaml と一致させる
```

---

## 🚨 トラブルシューティング / Troubleshooting

### APK ビルドが失敗する

**症状:** 5-6 分後にビルド失敗、メモリエラー

**対策:**
1. `android/gradle.properties` を確認 (Xmx と MaxMetaspaceSize)
2. メモリ設定を増やす
   ```properties
   org.gradle.jvmargs=-Xmx3072m -XX:+UseSerialGC -XX:MaxMetaspaceSize=1536m
   ```

### gradle-wrapper.jar が見つからない

**症状:** Gradle wrapper エラー

**対策:** ワークフロー内の "Ensure Gradle wrapper JAR" ステップが自動生成を行います。手動の場合：
```bash
cd android
gradle wrapper --gradle-version 9.1.0 --distribution-type all
```

### iOS ビルドが失敗する (macOS 環境)

**症状:** IPA ビルド失敗、`continue-on-error: true` でスキップ

**対策:**
- Xcode バージョン確認
- CocoaPods キャッシュをクリア
- ワークフローで `setup-ios-environment` ステップ追加

### google-services.json エラー

**症状:** Firebase プラグイン初期化失敗

**対策:**
1. Secret が正しく設定されているか確認
2. Base64 エンコード/デコードが正しいか確認
   ```bash
   # 確認用
   echo "$GOOGLE_SERVICES_JSON" | base64 -d | head -5
   ```

---

## 📞 サポート / Support

ワークフロー問題やビルドエラーは、以下を確認してください：

- ✅ GitHub Actions ログ (Workflow > Run > Job > Step)
- ✅ `android/gradle.properties` メモリ設定
- ✅ `GOOGLE_SERVICES_JSON` Secret 登録
- ✅ Flutter・Dart・AGP・Kotlin バージョン互換性

---

**最終更新:** 2026-09-10
**作成者:** Claude Code
**対象プロジェクト:** 近場コレ (chikaba_kore) v1.0.0+
