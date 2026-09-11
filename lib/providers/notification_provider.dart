import 'package:riverpod/riverpod.dart';
import '../models/notification_model.dart';
import '../services/enhanced_notification_service.dart';

/// Enhanced notification service provider
final enhancedNotificationServiceProvider = Provider((ref) {
  return EnhancedNotificationService();
});

/// Get user ID from auth provider (dependency injection)
final _userIdProvider = StateProvider<String?>((ref) => null);

/// Notification preferences provider
final notificationPreferencesProvider =
    FutureProvider.autoDispose.family<NotificationPreferences, String>(
      (ref, userId) async {
        final service = ref.watch(enhancedNotificationServiceProvider);
        return service.getPreferences(userId);
      },
    );

/// Stream notification preferences
final notificationPreferencesStreamProvider =
    StreamProvider.autoDispose.family<NotificationPreferences, String>(
      (ref, userId) {
        final service = ref.watch(enhancedNotificationServiceProvider);
        return service.getPreferences(userId).then((prefs) {
          // Return a stream that emits the initial value
          return Stream.value(prefs);
        }).asStream().expand((element) => element);
      },
    );

/// Unread notifications provider
final unreadNotificationsProvider =
    FutureProvider.autoDispose.family<List<AppNotification>, String>(
      (ref, userId) async {
        final service = ref.watch(enhancedNotificationServiceProvider);
        return service.getUnreadNotifications(userId);
      },
    );

/// Stream unread notifications
final unreadNotificationsStreamProvider =
    StreamProvider.autoDispose.family<List<AppNotification>, String>(
      (ref, userId) {
        final service = ref.watch(enhancedNotificationServiceProvider);
        return service.streamUnreadNotifications(userId);
      },
    );

/// All notifications provider (paginated)
final notificationsProvider =
    FutureProvider.autoDispose.family<List<AppNotification>, String>(
      (ref, userId) async {
        final service = ref.watch(enhancedNotificationServiceProvider);
        return service.getNotifications(userId);
      },
    );

/// Stream all notifications
final notificationsStreamProvider =
    StreamProvider.autoDispose.family<List<AppNotification>, String>(
      (ref, userId) {
        final service = ref.watch(enhancedNotificationServiceProvider);
        return service.streamNotifications(userId);
      },
    );

/// Notification statistics provider
final notificationStatsProvider =
    FutureProvider.autoDispose.family<NotificationStats, String>(
      (ref, userId) async {
        final service = ref.watch(enhancedNotificationServiceProvider);
        return service.getNotificationStats(userId);
      },
    );

/// Stream notification statistics
final notificationStatsStreamProvider =
    StreamProvider.autoDispose.family<NotificationStats, String>(
      (ref, userId) {
        final service = ref.watch(enhancedNotificationServiceProvider);
        return service.streamNotificationStats(userId);
      },
    );

/// Filter notifications by type
final filteredNotificationsProvider =
    FutureProvider.autoDispose
        .family<List<AppNotification>, (String userId, NotificationType type)>(
          (ref, params) async {
            final (userId, type) = params;
            final service = ref.watch(enhancedNotificationServiceProvider);
            final notifications = await service.getNotifications(userId);
            return notifications.where((n) => n.type == type).toList();
          },
        );

/// Stream filtered notifications
final filteredNotificationsStreamProvider =
    StreamProvider.autoDispose
        .family<List<AppNotification>, (String userId, NotificationType type)>(
          (ref, params) {
            final (userId, type) = params;
            final service = ref.watch(enhancedNotificationServiceProvider);
            return service.streamNotifications(userId).map(
                  (notifications) =>
                      notifications.where((n) => n.type == type).toList(),
                );
          },
        );

/// Current user ID provider (to be set by auth)
final currentUserIdProvider = StateProvider<String?>((ref) => null);

/// Grouped notifications by date
final groupedNotificationsProvider =
    FutureProvider.autoDispose.family<
        Map<String, List<AppNotification>>,
        String>((ref, userId) async {
  final service = ref.watch(enhancedNotificationServiceProvider);
  final notifications = await service.getNotifications(userId);

  final grouped = <String, List<AppNotification>>{};
  for (final notification in notifications) {
    final dateKey = _formatDate(notification.timestamp);
    grouped.putIfAbsent(dateKey, () => []).add(notification);
  }

  return grouped;
});

/// Mark notification as read notifier
class MarkAsReadNotifier extends StateNotifier<AsyncValue<void>> {
  MarkAsReadNotifier(this._service) : super(const AsyncValue.data(null));

  final EnhancedNotificationService _service;

  Future<void> markAsRead(String userId, String notificationId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.markAsRead(userId, notificationId),
    );
  }

  Future<void> markAllAsRead(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.markAllAsRead(userId),
    );
  }
}

/// Mark as read provider
final markAsReadProvider = StateNotifierProvider.autoDispose<
    MarkAsReadNotifier,
    AsyncValue<void>>((ref) {
  final service = ref.watch(enhancedNotificationServiceProvider);
  return MarkAsReadNotifier(service);
});

/// Archive notification notifier
class ArchiveNotificationNotifier extends StateNotifier<AsyncValue<void>> {
  ArchiveNotificationNotifier(this._service)
      : super(const AsyncValue.data(null));

  final EnhancedNotificationService _service;

  Future<void> archive(String userId, String notificationId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.archiveNotification(userId, notificationId),
    );
  }
}

/// Archive notification provider
final archiveNotificationProvider =
    StateNotifierProvider.autoDispose<ArchiveNotificationNotifier, AsyncValue<void>>(
      (ref) {
        final service = ref.watch(enhancedNotificationServiceProvider);
        return ArchiveNotificationNotifier(service);
      },
    );

/// Delete notification notifier
class DeleteNotificationNotifier extends StateNotifier<AsyncValue<void>> {
  DeleteNotificationNotifier(this._service)
      : super(const AsyncValue.data(null));

  final EnhancedNotificationService _service;

  Future<void> delete(String userId, String notificationId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.deleteNotification(userId, notificationId),
    );
  }
}

/// Delete notification provider
final deleteNotificationProvider =
    StateNotifierProvider.autoDispose<DeleteNotificationNotifier, AsyncValue<void>>(
      (ref) {
        final service = ref.watch(enhancedNotificationServiceProvider);
        return DeleteNotificationNotifier(service);
      },
    );

/// Notification filter state
final notificationFilterProvider = StateProvider<NotificationType?>((ref) => null);

/// Notification sorting preference
enum NotificationSortOrder {
  newest,
  oldest,
  priority,
}

final notificationSortOrderProvider =
    StateProvider<NotificationSortOrder>((ref) => NotificationSortOrder.newest);

/// Sorted notifications
final sortedNotificationsProvider = FutureProvider.autoDispose
    .family<List<AppNotification>, String>((ref, userId) async {
  final service = ref.watch(enhancedNotificationServiceProvider);
  final sortOrder = ref.watch(notificationSortOrderProvider);
  final notifications = await service.getNotifications(userId);

  switch (sortOrder) {
    case NotificationSortOrder.newest:
      return notifications;
    case NotificationSortOrder.oldest:
      return notifications.reversed.toList();
    case NotificationSortOrder.priority:
      notifications.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      return notifications;
  }
});

/// Date formatting helper
String _formatDate(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

  if (date == today) {
    return '今日';
  } else if (date == yesterday) {
    return '昨日';
  } else {
    return '${date.month}月${date.day}日';
  }
}
