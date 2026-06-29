import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/router.dart';
import 'config/theme/app_theme.dart';
import 'services/cache_service.dart';
import 'services/notification_service.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await CacheService.init();

  // firebase_options.dart が生成されるまでは条件付き初期化
  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
  } catch (e) {
    appLogger.w('Firebase init skipped (configure firebase_options.dart): $e');
  }

  runApp(const ProviderScope(child: ChikabaKoreApp()));
}

class ChikabaKoreApp extends StatelessWidget {
  const ChikabaKoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '近場コレ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
