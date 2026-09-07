#!/bin/bash
# ビルド完了フック: 改修セッション時の自動テスト実行

# 環境変数から対象アプリ名を取得
APP_NAME="${BUILD_TARGET:-${CI_APP:-}}"

if [ -n "$APP_NAME" ]; then
  echo "🎯 自動テスト実行: $APP_NAME"
  /build-and-test "$APP_NAME"
else
  echo "⚠️  BUILD_TARGET が設定されていません"
fi
