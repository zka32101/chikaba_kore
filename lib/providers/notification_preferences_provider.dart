import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/notification_service.dart';

const _kNotifEnabledKey = 'notifications_enabled';
const _kNotifTopicGeneral = 'general';

class NotificationPreferencesNotifier extends StateNotifier<bool> {
  NotificationPreferencesNotifier() : super(_loadFromHive());

  static bool _loadFromHive() {
    final box = Hive.box('user');
    return box.get(_kNotifEnabledKey, defaultValue: true) as bool;
  }

  Future<void> toggle() async {
    final newValue = !state;
    final box = Hive.box('user');
    await box.put(_kNotifEnabledKey, newValue);
    if (newValue) {
      await NotificationService().subscribeToTopic(_kNotifTopicGeneral);
    } else {
      await NotificationService().unsubscribeFromTopic(_kNotifTopicGeneral);
    }
    state = newValue;
  }

  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    await toggle();
  }
}

final notificationPreferencesProvider =
    StateNotifierProvider<NotificationPreferencesNotifier, bool>(
  (ref) => NotificationPreferencesNotifier(),
);
