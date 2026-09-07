#!/bin/bash
# ネットワーク有効化環境セットアップスクリプト
# 算数・国語など教科アプリビルド用

set -e

echo "========================================="
echo "🌐 ネットワーク有効化環境セットアップ"
echo "========================================="
echo ""

# 1. 環境変数確認
echo "📋 現在の環境確認..."
echo "   HTTPS_PROXY: ${HTTPS_PROXY:-未設定}"
echo "   HTTP_PROXY: ${HTTP_PROXY:-未設定}"
echo ""

# 2. プロキシ無効化
echo "🔓 プロキシ設定を解除..."
unset HTTPS_PROXY
unset HTTP_PROXY
unset NO_PROXY
unset http_proxy
unset https_proxy
unset no_proxy
echo "✅ プロキシ解除完了"
echo ""

# 3. npm 設定
echo "📦 npm 設定を更新..."
npm config set prefer-offline false
npm config set strict-ssl false
npm config set fetch-timeout 60000
echo "✅ npm 設定更新完了"
echo ""

# 4. npm キャッシュクリア
echo "🧹 npm キャッシュをクリア..."
npm cache clean --force
echo "✅ キャッシュクリア完了"
echo ""

# 5. Dart/Flutter 設定
echo "🎯 Dart/Flutter 設定..."
export FLUTTER_ALWAYS_USE_HTTP_CLIENT=true
export FLUTTER_ALWAYS_USE_HTTP_UPGRADE=true
echo "✅ Flutter 設定完了"
echo ""

# 6. ネットワーク接続テスト
echo "🔌 ネットワーク接続テスト..."
if curl -s -m 5 https://pub.dev > /dev/null 2>&1; then
    echo "✅ pub.dev に接続確認"
else
    echo "⚠️  pub.dev に接続できません（オフライン環境の可能性）"
fi

if curl -s -m 5 https://registry.npmjs.org > /dev/null 2>&1; then
    echo "✅ npm registry に接続確認"
else
    echo "⚠️  npm registry に接続できません（オフライン環境の可能性）"
fi
echo ""

# 7. Docker コンテナ起動（オプション）
if [ -f "docker-compose.yml" ]; then
    echo "🐳 Docker コンテナ起動..."
    if command -v docker-compose &> /dev/null; then
        echo "   実行: docker-compose -f docker-compose.yml -f docker-compose.network-enabled.yml up -d claude"
        read -p "   実行しますか？ (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose -f docker-compose.yml -f docker-compose.network-enabled.yml up -d claude
            echo "✅ Docker コンテナ起動完了"
        fi
    fi
fi
echo ""

# 8. セットアップ完了
echo "========================================="
echo "✅ ネットワーク有効化環境セットアップ完了"
echo "========================================="
echo ""
echo "📚 次のステップ:"
echo ""
echo "1️⃣  アプリビルド（単一）"
echo "   /build-and-test shoukoku_kokugo"
echo ""
echo "2️⃣  全アプリビルド"
echo "   ./scripts/build.sh flutter:shoukoku_kokugo"
echo "   ./scripts/build.sh flutter:shoukoku_eigo"
echo "   ./scripts/build.sh flutter:shoukoku_programming"
echo "   ./scripts/build.sh flutter:shoukoku_shinshin"
echo ""
echo "3️⃣  Docker コンテナ内で作業"
echo "   docker-compose exec claude bash"
echo ""
echo "トラブル時:"
echo "   - cat .env で環境変数確認"
echo "   - npm config list で npm 設定確認"
echo "   - curl -v https://pub.dev でネットワーク接続テスト"
echo ""
