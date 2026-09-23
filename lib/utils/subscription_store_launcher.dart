import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// ストアのサブスクリプション管理画面を開くヘルパー。
/// プラン変更・解約は各ストアの管理画面で行う（アプリ内からは操作できない）。
class SubscriptionStoreLauncher {
  SubscriptionStoreLauncher._();

  /// 現在のプラットフォームでサブスクリプション管理画面を開けるか。
  static bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  static Future<void> openManageSubscription() async {
    if (kIsWeb) return;
    final url = Platform.isIOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
