import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../utils/logger.dart';

class NotificationCenterScreen extends ConsumerWidget {
  final String userId;

  const NotificationCenterScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(
      sortedNotificationsProvider(userId),
    );
    final filterType = ref.watch(notificationFilterProvider);
    final sortOrder = ref.watch(notificationSortOrderProvider);
    final statsAsync = ref.watch(notificationStatsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知センター'),
        elevation: 0,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(sortedNotificationsProvider(userId));
              ref.refresh(notificationStatsProvider(userId));
            },
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context, ref, userId),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラーが発生しました: $error'),
        ),
        data: (notifications) {
          // Filter notifications
          final filtered = filterType != null
              ? notifications.where((n) => n.type == filterType).toList()
              : notifications;

          if (filtered.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Stats bar
              if (statsAsync.hasValue)
                _buildStatsBar(statsAsync.value!),

              // Filter and sort controls
              _buildControlsBar(context, ref, filterType, sortOrder),

              // Notifications list
              Expanded(
                child: _buildNotificationsList(
                  context,
                  ref,
                  filtered,
                  userId,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsBar(NotificationStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.blue[200]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '未読',
            stats.unreadNotifications.toString(),
            Colors.red,
          ),
          _buildStatItem(
            '本日',
            stats.todayNotifications.toString(),
            Colors.orange,
          ),
          _buildStatItem(
            '合計',
            stats.totalNotifications.toString(),
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildControlsBar(
    BuildContext context,
    WidgetRef ref,
    NotificationType? filterType,
    NotificationSortOrder sortOrder,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Filter dropdown
          Expanded(
            child: PopupMenuButton<NotificationType?>(
              initialValue: filterType,
              onSelected: (type) {
                ref.read(notificationFilterProvider.notifier).state = type;
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('すべての通知'),
                ),
                for (final type in NotificationType.values)
                  PopupMenuItem(
                    value: type,
                    child: Text(_getNotificationTypeLabel(type)),
                  ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      filterType != null
                          ? _getNotificationTypeLabel(filterType)
                          : 'すべて',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sort dropdown
          PopupMenuButton<NotificationSortOrder>(
            initialValue: sortOrder,
            onSelected: (order) {
              ref.read(notificationSortOrderProvider.notifier).state = order;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: NotificationSortOrder.newest,
                child: Text('新しい順'),
              ),
              const PopupMenuItem(
                value: NotificationSortOrder.oldest,
                child: Text('古い順'),
              ),
              const PopupMenuItem(
                value: NotificationSortOrder.priority,
                child: Text('優先度順'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sort, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    WidgetRef ref,
    List<AppNotification> notifications,
    String userId,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationItem(
          context,
          ref,
          notification,
          userId,
        );
      },
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
    String userId,
  ) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red[50],
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(deleteNotificationProvider.notifier).delete(
              userId,
              notification.id,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('通知を削除しました')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.blue[50],
          border: Border(
            left: BorderSide(
              color: _getPriorityColor(notification.priority),
              width: 4,
            ),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: _buildNotificationIcon(notification.type),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(notification.timestamp),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: !notification.isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () {
            if (!notification.isRead) {
              ref.read(markAsReadProvider.notifier).markAsRead(
                    userId,
                    notification.id,
                  );
            }
            _handleNotificationTap(context, notification);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '通知はありません',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    final icon = switch (type) {
      NotificationType.facilityUpdate => Icons.location_on,
      NotificationType.newReview => Icons.comment,
      NotificationType.reviewLike => Icons.favorite,
      NotificationType.favoriteFacility => Icons.star,
      NotificationType.localQA => Icons.help,
      NotificationType.community => Icons.people,
      NotificationType.announcement => Icons.notifications,
      NotificationType.promotion => Icons.local_offer,
    };

    return Icon(icon, color: Colors.blue);
  }

  Color _getPriorityColor(NotificationPriority priority) {
    return switch (priority) {
      NotificationPriority.low => Colors.grey,
      NotificationPriority.normal => Colors.blue,
      NotificationPriority.high => Colors.red,
    };
  }

  String _getNotificationTypeLabel(NotificationType type) {
    return switch (type) {
      NotificationType.facilityUpdate => '施設更新',
      NotificationType.newReview => '新着レビュー',
      NotificationType.reviewLike => 'いいね',
      NotificationType.favoriteFacility => 'お気に入り',
      NotificationType.localQA => 'ローカルQ&A',
      NotificationType.community => 'コミュニティ',
      NotificationType.announcement => 'お知らせ',
      NotificationType.promotion => 'キャンペーン',
    };
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return '今';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}時間前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}日前';
    } else {
      return '${dateTime.month}月${dateTime.day}日';
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    AppNotification notification,
  ) {
    // Handle navigation based on notification type and metadata
    final facilityId = notification.metadata['facilityId'] as String?;
    final reviewId = notification.metadata['reviewId'] as String?;

    if (facilityId != null) {
      // Navigate to facility detail
      // context.go('/facility/$facilityId');
    } else if (reviewId != null) {
      // Navigate to review
      // context.go('/review/$reviewId');
    }

    appLogger.d('Notification tapped: ${notification.type}, $facilityId');
  }

  void _showSettings(BuildContext context, WidgetRef ref, String userId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => NotificationSettingsSheet(userId: userId),
    );
  }
}

/// Notification settings sheet
class NotificationSettingsSheet extends ConsumerWidget {
  final String userId;

  const NotificationSettingsSheet({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPreferencesProvider(userId));

    return prefsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('エラー: $error'),
      ),
      data: (prefs) => _buildSettings(context, ref, prefs, userId),
    );
  }

  Widget _buildSettings(
    BuildContext context,
    WidgetRef ref,
    NotificationPreferences prefs,
    String userId,
  ) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '通知設定',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildToggleSetting(
              'ラベル',
              '施設の更新',
              prefs.enableFacilityUpdates,
              (value) => _updatePreference(
                ref,
                userId,
                prefs.copyWith(enableFacilityUpdates: value),
              ),
            ),
            _buildToggleSetting(
              'ラベル',
              '新着レビュー',
              prefs.enableReviews,
              (value) => _updatePreference(
                ref,
                userId,
                prefs.copyWith(enableReviews: value),
              ),
            ),
            _buildToggleSetting(
              'ラベル',
              'いいね通知',
              prefs.enableLikes,
              (value) => _updatePreference(
                ref,
                userId,
                prefs.copyWith(enableLikes: value),
              ),
            ),
            _buildToggleSetting(
              'ラベル',
              'コミュニティ通知',
              prefs.enableCommunity,
              (value) => _updatePreference(
                ref,
                userId,
                prefs.copyWith(enableCommunity: value),
              ),
            ),
            _buildToggleSetting(
              'ラベル',
              'サウンド',
              prefs.enableSoundNotifications,
              (value) => _updatePreference(
                ref,
                userId,
                prefs.copyWith(enableSoundNotifications: value),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSetting(
    String category,
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _updatePreference(
    WidgetRef ref,
    String userId,
    NotificationPreferences prefs,
  ) {
    ref.read(enhancedNotificationServiceProvider).updatePreferences(userId, prefs);
  }
}
