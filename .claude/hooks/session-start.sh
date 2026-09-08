#!/bin/bash
set -euo pipefail

# SessionStart Hook for chikaba_kore
# Automatically runs when a new Claude Code session starts
# Sets up Flutter dependencies and runs linting/tests

echo "🚀 chikaba_kore セッション初期化開始..."

# 1. Flutter 依存関係をインストール
echo "📦 Flutter 依存関係をインストール中..."
flutter pub get

# 2. コード分析を実行
echo "🔍 コード分析を実行中..."
flutter analyze --no-fatal-infos --no-fatal-warnings || true

# 3. ビルド・テストスキルの準備確認
if [ -f ".claude/skills/build-and-test/SKILL.md" ]; then
    echo "✅ build-and-test スキルが利用可能です"
fi

echo "✅ セッション初期化完了！"
echo ""
echo "📝 次のステップ:"
echo "  1. コードを修正"
echo "  2. /build-and-test でエミュレータテストを実行"
echo ""
