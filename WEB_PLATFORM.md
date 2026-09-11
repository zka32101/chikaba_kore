# Web Platform Optimization Guide

**バージョン**: 1.0.0
**最終更新**: 2026年9月

## 目次

- [概要](#概要)
- [PWA機能](#pwa機能)
- [パフォーマンス最適化](#パフォーマンス最適化)
- [オフライン対応](#オフライン対応)
- [レスポンシブデザイン](#レスポンシブデザイン)
- [ビルドと最適化](#ビルドと最適化)
- [デプロイメント](#デプロイメント)
- [監視と分析](#監視と分析)

## 概要

このガイドは、近場コレのFlutter Web版を最適化し、Progressive Web App (PWA) として機能させるための手引きです。

### 目標

- **オフラインサポート** — インターネット接続がない状態でも基本機能が使用可能
- **高速読み込み** — 初回読み込み時間 < 3秒
- **モバイル最適化** — すべてのデバイスで快適に使用可能
- **キャッシング** — 効率的なリソースキャッシングでバンド幅削減

## PWA機能

### Manifest.json 設定

```json
{
  "name": "近場コレ - 施設発見プラットフォーム",
  "short_name": "近場コレ",
  "display": "standalone",
  "start_url": "/?utm_source=pwa",
  "theme_color": "#2196F3",
  "background_color": "#FFFFFF"
}
```

### インストール方法

**Chrome/Edge/Firefox:**
1. アドレスバーの「インストール」をクリック
2. アプリがホーム画面に追加される

**iOS (Safari):**
1. 共有ボタンをタップ
2. 「ホーム画面に追加」を選択

**Android:**
1. メニューボタン ⋮ をタップ
2. 「インストール」を選択

### PWA機能一覧

| 機能 | 状態 | 説明 |
|-----|------|------|
| **Install** | ✅ | ホーム画面にインストール可能 |
| **Offline** | ✅ | オフラインモード対応 |
| **App Mode** | ✅ | Standalone モード |
| **Push Notifications** | ✅ | サポート |
| **Background Sync** | ✅ | バックグラウンド同期 |
| **Share Target** | ✅ | Web Share API対応 |

## パフォーマンス最適化

### 1. バンドルサイズ最適化

```bash
# Web ビルドで最適化有効
flutter build web --release --web-renderer canvaskit --dart-deferred-components

# またはHTML Rendererを使用（軽量）
flutter build web --release --web-renderer html
```

**推奨: HTML Renderer** — サイズが小さい（ファイルサイズ: 〜2MB）

### 2. 画像最適化

```dart
// 最適な画像フォーマット選択
Image.network(
  url,
  cacheHeight: 300,
  cacheWidth: 300,
  fit: BoxFit.cover,
)
```

**画像最適化チェックリスト:**
- WebP形式を優先（JPEGより30%小さい）
- 解像度を適切に設定
- Lazy loadingを実装
- CDNでキャッシュ

### 3. JavaScriptバンドルの最適化

```bash
# デバッグ情報を除去
flutter build web --release --no-source-maps

# Tree shakingを有効化
flutter build web --release --dart-define=dart.vm.profile=false
```

### 4. CSS/フォント最適化

```html
<!-- フォント読み込みを最適化 -->
<link rel="preload" as="font" href="fonts/NotoSansJP.woff2" type="font/woff2" crossorigin>

<!-- Subset フォント -->
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;500;700&display=swap" rel="stylesheet">
```

### 5. キャッシング戦略

```javascript
// service_worker.js の戦略

// 静的資産 → キャッシュ優先
// - CSS, JS, 画像, フォント

// API呼び出し → ネットワーク優先
// - /api/* → ネットワークを試す → キャッシュにフォールバック

// その他 → ネットワークのみ
// - POST, PUT, DELETE
```

## オフライン対応

### Service Worker 機能

```javascript
// オフライン時の動作
1. 読み取り専用操作（GET） → キャッシュから返却
2. ネットワーク操作（POST） → キューに保存、オンライン時に同期
3. エラー発生 → ユーザーフレンドリーなエラーメッセージ
```

### IndexedDB を使用したローカル保存

```dart
// Dartでのオフラインデータ管理
class OfflineStorage {
  static const String _storeName = 'pending_reviews';

  Future<void> savePendingReview(Review review) async {
    final box = await openLocalBox();
    await box.put('pending_${review.id}', review.toJson());
  }

  Future<void> syncPendingReviews() async {
    final box = await openLocalBox();
    final pending = box.toMap();

    for (final entry in pending.entries) {
      try {
        await submitReview(entry.value);
        await box.delete(entry.key);
      } catch (e) {
        print('Sync failed: $e');
      }
    }
  }
}
```

### バックグラウンド同期

```dart
// 背景同期の登録（Webのみ）
if (kIsWeb) {
  await ServiceWorkerManager.instance.registerBackgroundSync('sync-reviews');
}
```

## レスポンシブデザイン

### ブレークポイント

```dart
enum DeviceSize {
  mobile,    // 0px - 599px
  tablet,    // 600px - 999px
  desktop,   // 1000px+
}

DeviceSize getDeviceSize(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < 600) return DeviceSize.mobile;
  if (width < 1000) return DeviceSize.tablet;
  return DeviceSize.desktop;
}
```

### Webレイアウト最適化

```dart
// Web特有のレイアウト
class ResponsiveLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Responsive(
      mobile: MobileLayout(),
      tablet: TabletLayout(),
      desktop: DesktopLayout(),
    );
  }
}
```

### ブラウザウィンドウリサイズ対応

```dart
// ウィンドウサイズ変更を監視
class ResponsiveScaffold extends StatefulWidget {
  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ウィンドウサイズ変更時に再構築
    setState(() {});
  }
}
```

## ビルドと最適化

### ビルドコマンド

```bash
# 推奨: HTML Renderer + 最適化
flutter build web --release \
  --web-renderer html \
  --no-sound-null-safety \
  --dart-define=dart.vm.profile=false

# 出力ディレクトリ: build/web/
```

### ビルド出力の検査

```bash
# ビルド成果物のサイズを確認
ls -lh build/web/

# 合計サイズ
du -sh build/web/
```

### 推奨ファイルサイズ

```
main.dart.js          < 2.5 MB
flutter_service_worker.js (自動生成)
flutter_web_plugins/  < 1 MB
assets/               < 50 MB
```

## デプロイメント

### Firebase Hosting へのデプロイ

```bash
# Firebase CLI のインストール
npm install -g firebase-tools

# ログイン
firebase login

# 初期化（1回のみ）
firebase init hosting

# デプロイ
flutter build web --release
firebase deploy
```

### Firebase Hosting 設定 (firebase.json)

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*"],
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=3600"
          }
        ]
      },
      {
        "source": "**/*.js",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      },
      {
        "source": "index.html",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=0, must-revalidate"
          }
        ]
      }
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### HTTPS と SSL/TLS

- Firebase Hosting はデフォルトで HTTPS対応
- 自動 SSL 証明書管理
- 全トラフィックが暗号化される

### CDN キャッシング戦略

```
静的アセット (JS, CSS, 画像)
└─ Cache-Control: public, max-age=31536000 (1年)
└─ ファイルハッシュで変更検出

index.html
└─ Cache-Control: public, max-age=0, must-revalidate
└─ 常に最新を確認
```

## 監視と分析

### ウェブ性能メトリクス

```dart
// Core Web Vitals の測定
import 'package:web/web.dart' as web;

void measureWebVitals() {
  // Largest Contentful Paint (LCP)
  web.PerformanceEntryList entries = web.window.performance
      .getEntriesByName('largest-contentful-paint');

  // First Input Delay (FID)
  // First Contentful Paint (FCP)
}
```

### Google Analytics 統合

```html
<!-- Google Analytics in index.html -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

### 監視項目

| メトリクス | 目標 | 注釈 |
|-----------|------|------|
| **LCP** | < 2.5s | Largest Contentful Paint |
| **FID** | < 100ms | First Input Delay |
| **CLS** | < 0.1 | Cumulative Layout Shift |
| **TTFB** | < 1.3s | Time to First Byte |
| **FCP** | < 1.8s | First Contentful Paint |

### パフォーマンス測定

```bash
# Lighthouse を使用してパフォーマンス分析
npm install -g @lhci/cli@latest

# スコア測定
lhci autorun
```

## トラブルシューティング

### Service Worker が登録されない

```javascript
// ブラウザコンソールで確認
navigator.serviceWorker.getRegistrations().then(registrations => {
  console.log('Registered Service Workers:', registrations);
});
```

### キャッシュが古い

```bash
# キャッシュクリア方法
1. DevTools > Application > Storage > Clear site data
2. または: Ctrl+Shift+Delete (Windows) / Cmd+Shift+Delete (Mac)
```

### CORS エラー

```dart
// API呼び出し時は認証トークンを含める
final response = await http.get(
  Uri.parse(url),
  headers: {
    'Authorization': 'Bearer $token',
  },
);
```

### オフラインモード確認

1. DevTools > Network > Offline チェック
2. アプリが正常に動作することを確認

---

## ベストプラクティス

1. **定期的なパフォーマンス測定**
   - 本番環境で Lighthouse を実行
   - Core Web Vitals を監視

2. **キャッシング戦略**
   - 長期キャッシュ: ハッシュ付きアセット
   - 短期キャッシュ: index.html, API

3. **エラーハンドリング**
   - オフライン時のUIフィードバック
   - ネットワークエラーの適切な通知

4. **セキュリティ**
   - HTTPS必須
   - CSP (Content Security Policy) 設定
   - XSS対策

このドキュメントは定期的に更新されます。
最終更新: 2026年9月
