import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/notification_service.dart';
import '../utils/business_hours_parser.dart';
import 'facility_provider.dart';
import 'favorite_provider.dart';

const _kBusinessHoursNotifEnabledKey = 'business_hours_notifications_enabled';

/// 開店前・閉店前に通知する時間（固定値、設定項目は設けない）。
const _openingSoonLead = Duration(minutes: 15);
const _closingSoonLead = Duration(minutes: 30);

const _weekdayKeys = ['月', '火', '水', '木', '金', '土', '日'];

/// お気に入り（「行きたい」リスト）の施設について、今日の営業時間を基準に
/// 「開店間近」「閉店間近」の端末内ローカル通知を予約する。既存のプッシュ通知
/// （`notificationPreferencesProvider`）とは独立したON/OFF設定を持つ。
class BusinessHoursNotificationNotifier extends StateNotifier<bool> {
  final Ref _ref;
  BusinessHoursNotificationNotifier(this._ref) : super(_loadFromHive());

  static bool _loadFromHive() {
    final box = Hive.box('user');
    return box.get(_kBusinessHoursNotifEnabledKey, defaultValue: false) as bool;
  }

  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    await Hive.box('user').put(_kBusinessHoursNotifEnabledKey, enabled);
    state = enabled;
    if (enabled) {
      await reschedule();
    } else {
      await _cancelAll();
    }
  }

  /// `facilityId`から「開店」「閉店」それぞれの通知IDを生成する（int32範囲に収める）。
  int _notificationId(String facilityId, {required bool isOpening}) {
    final base = facilityId.hashCode & 0x3FFFFFFF;
    return isOpening ? base * 2 : base * 2 + 1;
  }

  Future<void> _cancelAll() async {
    final favorites = _ref.read(wantToGoProvider);
    for (final fav in favorites) {
      await NotificationService()
          .cancelLocalNotification(_notificationId(fav.facilityId, isOpening: true));
      await NotificationService()
          .cancelLocalNotification(_notificationId(fav.facilityId, isOpening: false));
    }
  }

  /// お気に入りの「行きたい」リストを基に、今日分の通知を再計算して予約する。
  /// アプリ起動時やお気に入りの変更時に呼ぶ想定。既に過去の時刻になった
  /// 通知は予約しない（[NotificationService.scheduleLocalNotification]が無視する）。
  Future<void> reschedule() async {
    await _cancelAll();
    if (!state) return;

    final favorites = _ref.read(wantToGoProvider);
    final repo = _ref.read(facilityRepositoryProvider);
    final now = DateTime.now();
    final todayKey = _weekdayKeys[(now.weekday - 1) % 7];

    for (final fav in favorites) {
      final facility = await repo.getById(fav.facilityId);
      if (facility == null) continue;
      final hoursText = facility.businessHours[todayKey];
      if (hoursText == null) continue;
      final range = parseBusinessHoursRange(hoursText);
      if (range == null) continue;

      final openTime =
          DateTime(now.year, now.month, now.day, range.open.hour, range.open.minute);
      final closeTime =
          DateTime(now.year, now.month, now.day, range.close.hour, range.close.minute);

      await NotificationService().scheduleLocalNotification(
        id: _notificationId(fav.facilityId, isOpening: true),
        title: '${facility.name}がもうすぐ開店します',
        scheduledTime: openTime.subtract(_openingSoonLead),
        body:
            '${_openingSoonLead.inMinutes}分後に開店予定です（${_formatTime(range.open)}〜）',
        payload: fav.facilityId,
      );
      await NotificationService().scheduleLocalNotification(
        id: _notificationId(fav.facilityId, isOpening: false),
        title: '${facility.name}がもうすぐ閉店します',
        scheduledTime: closeTime.subtract(_closingSoonLead),
        body:
            '${_closingSoonLead.inMinutes}分後に閉店予定です（〜${_formatTime(range.close)}）',
        payload: fav.facilityId,
      );
    }
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

final businessHoursNotificationProvider =
    StateNotifierProvider<BusinessHoursNotificationNotifier, bool>(
  (ref) => BusinessHoursNotificationNotifier(ref),
);
