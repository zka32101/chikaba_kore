# ネットワークポリシー対応環境設定

算数・国語アプリのビルドに対応したネットワーク有効化環境。

## 環境選択方法

### 方法1: リモートセッション環境設定（推奨）

新しいセッション起動時に以下を選択：

```
Environment Policy: allow-outbound-https
Network: unrestricted
```

または GitHub CLI で：
```bash
gh api -X POST /repos/zka32101/yourwish/sessions \
  -f "environment_policy=allow-outbound-https" \
  -f "network_policy=unrestricted"
```

### 方法2: 環境変数設定（現在のセッション）

```bash
# プロキシ設定を無効化
unset HTTPS_PROXY
unset HTTP_PROXY

# npm オフラインモードを無効化
npm config set prefer-offline false

# キャッシュクリア
npm cache clean --force
```

### 方法3: Docker 起動時オプション

```bash
# ネットワーク無制限で Docker コンテナ起動
docker-compose -f docker-compose.yml \
  -f docker-compose.network-enabled.yml \
  up -d claude
```

## 対応アプリ

- ✅ shoukoku_kokugo（小学国語）
- ✅ shoukoku_eigo（小学英語）
- ✅ shoukoku_programming（小学プログラミング）
- ✅ shoukoku_shinshin（小学心身）
- ✅ sansu-kore（小学算数）

## ビルドコマンド

```bash
# 国語アプリビルド
/build-and-test shoukoku_kokugo

# 全教科アプリビルド
./scripts/build.sh flutter:shoukoku_kokugo
./scripts/build.sh flutter:shoukoku_eigo
./scripts/build.sh flutter:shoukoku_programming
./scripts/build.sh flutter:shoukoku_shinshin
```

## トラブルシューティング

### エラー: Network unreachable

```bash
# 原因: 現在のセッションはネットワーク制限あり
# 解決: 新しいセッションを起動

# GitHub CLI で新セッション起動
gh codespace create -r zka32101/yourwish -b claude/continuation-session-9vahuc \
  --machine-type standard
```

### エラー: certificate verify failed

```bash
# 原因: プロキシの SSL 証明書検証エラー
# 解決: SSL 検証を無効化（開発環境のみ）

npm config set strict-ssl false
export NODE_TLS_REJECT_UNAUTHORIZED=0
```

## セッション環境のスペック確認

```bash
# 現在のネットワークポリシー確認
env | grep -i proxy

# Docker ネットワーク確認
docker network ls
docker network inspect bridge
```

## 関連ドキュメント

- `.claude/settings.json` - Claude Code 設定
- `docs/LOCAL_ENV_FREE_BUILD.md` - ビルドガイド
- `.github/workflows/flutter-app-ci.yml` - CI/CD 設定
