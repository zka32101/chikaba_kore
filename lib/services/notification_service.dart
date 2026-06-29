import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/router.dart';
import '../utils/logger.dart';

/// バックグラウンドハンドラ（トップレベル関数必須）
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  appLogger.d('Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'chikaba_kore_default';
  static const _channelName = '近場コレ通知';

  Future<void> initialize() async {
    // バックグラウンドハンドラ登録
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 通知権限
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    appLogger.d('Notification permission: ${settings.authorizationStatus}');

    // ローカル通知チャンネル（Android）
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Android 通知チャンネル
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: '近場コレからのお知らせ',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // フォアグラウンド通知の表示設定
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // フォアグラウンドでメッセージ受信したときはローカル通知を表示
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // バックグラウンドから復帰してタップされた場合
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigate);

    // アプリが終了状態からタップで起動した場合
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // ルーターが準備できてから遷移するよう少し遅延
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleMessageNavigate(initialMessage);
      });
    }
  }

  /// FCM メッセージのペイロードから遷移先を判断して画面遷移
  void _handleMessageNavigate(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final facilityId = data['facilityId'] as String?;

    appLogger.d('Notification tap: type=$type, facilityId=$facilityId');

    if (facilityId != null && facilityId.isNotEmpty) {
      appRouter.push('/facility/$facilityId');
      return;
    }
    switch (type) {
      case 'announcement':
        appRouter.go('/home');
      default:
        appRouter.go('/home');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      // ペイロードをローカル通知に埋め込む（タップ時に facilityId を受け取る）
      payload: message.data['facilityId'] as String?,
    );
  }

  /// ローカル通知（フォアグラウンド受信分）のタップ
  void _onLocalNotificationTap(NotificationResponse response) {
    final facilityId = response.payload;
    appLogger.d('Local notification tapped, facilityId=$facilityId');
    if (facilityId != null && facilityId.isNotEmpty) {
      appRouter.push('/facility/$facilityId');
    }
  }

  /// FCM トークンを取得（サーバーへの登録に使用）
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      appLogger.e('getToken error', error: e);
      return null;
    }
  }

  /// トピック購読
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    appLogger.d('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}
