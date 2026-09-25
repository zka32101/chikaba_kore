import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/router.dart';
import 'config/theme/app_theme.dart';
import 'models/app_notification.dart';
import 'providers/billing_provider.dart';
import 'providers/firebase_provider.dart';
import 'purchases/purchases_bootstrap.dart';
import 'services/cache_service.dart';
import 'services/notification_service.dart';
import 'utils/logger.dart';
import 'widgets/foreground_notification_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await CacheService.init();

  // firebase_options.dart が生成されるまでは条件付き初期化
  var firebaseAvailable = false;
  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
    firebaseAvailable = true;
  } catch (e) {
    appLogger.w('Firebase init skipped (configure firebase_options.dart): $e');
  }

  // RevenueCat APIキー未設定時は available: false を返し、
  // LocalSubscriptionService（デモ用フラグでの疑似購入）へ自動フォールバックする
  final purchasesResult = await bootstrapPurchases();

  runApp(ProviderScope(
    overrides: [
      purchasesAvailableProvider.overrideWithValue(purchasesResult.available),
      firebaseAvailableProvider.overrideWithValue(firebaseAvailable),
    ],
    child: const ChikabaKoreApp(),
  ));
}

class ChikabaKoreApp extends StatefulWidget {
  const ChikabaKoreApp({super.key});

  @override
  State<ChikabaKoreApp> createState() => _ChikabaKoreAppState();
}

class _ChikabaKoreAppState extends State<ChikabaKoreApp> {
  // 複数の通知がほぼ同時に届いても重ねて表示せず、1件ずつ直列に表示するキュー
  // （`widgets/foreground_notification_banner.dart`参照）。Appの生存期間中は1つのインスタンスを使い回す。
  final _bannerQueue = ForegroundBannerQueue();
  StreamSubscription<AppNotification>? _foregroundMessageSubscription;

  @override
  void initState() {
    super.initState();
    _foregroundMessageSubscription =
        NotificationService().foregroundMessages.listen(_showForegroundBanner);
  }

  @override
  void dispose() {
    _foregroundMessageSubscription?.cancel();
    super.dispose();
  }

  void _showForegroundBanner(AppNotification notification) {
    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _bannerQueue.enqueue(
      overlay,
      notification,
      onTap: () {
        final facilityId = notification.facilityId;
        if (facilityId != null && facilityId.isNotEmpty) {
          appRouter.push('/facility/$facilityId');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '近場まっぷ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
