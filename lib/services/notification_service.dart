import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../config/router.dart';
import '../models/app_notification.dart';
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
  final _foregroundMessageController =
      StreamController<AppNotification>.broadcast();

  /// フォアグラウンド受信したプッシュ通知。アプリ内バナー表示用。
  Stream<AppNotification> get foregroundMessages =>
      _foregroundMessageController.stream;

  static const _channelId = 'chikaba_kore_default';
  static const _channelName = '近場コレ通知';

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

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
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    // フォアグラウンド時はシステム側のアラート表示を抑止し、
    // アプリ内バナー（ForegroundBannerQueue）側で表示する
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

    // フォアグラウンドでメッセージ受信したときはアプリ内バナー用ストリームへ発行
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
        appRouter.push('/announcements');
      default:
        appRouter.go('/home');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _foregroundMessageController.add(
      AppNotification(
        title: notification.title ?? '',
        body: notification.body ?? '',
        facilityId: message.data['facilityId'] as String?,
      ),
    );
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

  /// 端末内にローカル通知を予約する（FCMを経由しない）。[scheduledTime]は
  /// ローカル時刻（例: `DateTime.now()`基準の時刻）を渡せばよく、内部でUTCの
  /// 絶対時刻に変換してからスケジュールするため、端末のタイムゾーン設定に
  /// 依存せず正確に発火する。過去の時刻が渡された場合は何もしない。
  Future<void> scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;
    final utc = scheduledTime.toUtc();
    final tzTime = tz.TZDateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
      utc.millisecond,
    );
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(_channelId, _channelName),
        iOS: DarwinNotificationDetails(),
      ),
      // 多少の遅延は許容できる通知のため、SCHEDULE_EXACT_ALARM権限を
      // 要求しない inexact モードを使う（Doze中でも発火する）。
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// [scheduleLocalNotification]で予約した通知をキャンセルする。
  Future<void> cancelLocalNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}
