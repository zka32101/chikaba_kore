import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';
import '../utils/logger.dart';

/// Enhanced notification service with notification center, preferences, and analytics
class EnhancedNotificationService {
  static final EnhancedNotificationService _instance = EnhancedNotificationService._();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._();

  final _firestore = FirebaseFirestore.instance;
  final _messaging = FirebaseMessaging.instance;

  static const String _notificationsCollection = 'notifications';
  static const String _preferencesCollection = 'notification_preferences';
  static const String _statsCollection = 'notification_stats';
  static const int _maxNotifications = 1000;
  static const Duration _notificationExpiry = Duration(days: 30);

  /// Create and send a notification
  Future<String> sendNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.normal,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    DateTime? expiresAt,
  }) async {
    try {
      final notificationDoc = _firestore
          .collection(_notificationsCollection)
          .doc(userId)
          .collection('messages')
          .doc();

      final notification = AppNotification(
        id: notificationDoc.id,
        userId: userId,
        type: type,
        priority: priority,
        title: title,
        body: body,
        imageUrl: imageUrl,
        metadata: metadata ?? {},
        timestamp: DateTime.now(),
        expiresAt: expiresAt ?? DateTime.now().add(_notificationExpiry),
      );

      await notificationDoc.set(notification.toFirestore());

      // Update statistics
      await _updateNotificationStats(userId, type);

      appLogger.d('Notification created: $userId, $type, $title');
      return notificationDoc.id;
    } catch (e) {
      appLogger.e('Error creating notification', error: e);
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(userId)
          .collection('messages')
          .doc(notificationId)
          .update({
            'isRead': true,
            'readAt': Timestamp.now(),
          });

      // Update unread count in stats
      await _updateUnreadCount(userId);
    } catch (e) {
      appLogger.e('Error marking notification as read', error: e);
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();

      final unreadNotifications = await _firestore
          .collection(_notificationsCollection)
          .doc(userId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();
      await _updateUnreadCount(userId);
      appLogger.d('All notifications marked as read for $userId');
    } catch (e) {
      appLogger.e('Error marking all notifications as read', error: e);
      rethrow;
    }
  }

  /// Archive notification
  Future<void> archiveNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(userId)
          .collection('messages')
          .doc(notificationId)
          .update({'isArchived': true});
    } catch (e) {
      appLogger.e('Error archiving notification', error: e);
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(userId)
          .collection('messages')
          .doc(notificationId)
          .delete();

      await _updateUnreadCount(userId);
    } catch (e) {
      appLogger.e('Error deleting notification', error: e);
      rethrow;
    }
  }

  /// Get unread notifications
  Future<List<AppNotification>> getUnreadNotifications(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .doc(userId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
    } catch (e) {
      appLogger.e('Error fetching unread notifications', error: e);
      rethrow;
    }
  }

  /// Stream unread notifications
  Stream<List<AppNotification>> streamUnreadNotifications(String userId) {
    return _firestore
        .collection(_notificationsCollection)
        .doc(userId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('isArchived', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs
                .map((doc) => AppNotification.fromFirestore(doc))
                .toList());
  }

  /// Get all notifications (paginated)
  Future<List<AppNotification>> getNotifications(
    String userId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = _firestore
          .collection(_notificationsCollection)
          .doc(userId)
          .collection('messages')
          .where('isArchived', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
    } catch (e) {
      appLogger.e('Error fetching notifications', error: e);
      rethrow;
    }
  }

  /// Stream all notifications
  Stream<List<AppNotification>> streamNotifications(String userId) {
    return _firestore
        .collection(_notificationsCollection)
        .doc(userId)
        .collection('messages')
        .where('isArchived', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs
                .map((doc) => AppNotification.fromFirestore(doc))
                .toList());
  }

  /// Get notification statistics
  Future<NotificationStats> getNotificationStats(String userId) async {
    try {
      final doc = await _firestore
          .collection(_statsCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return NotificationStats(
          userId: userId,
          totalNotifications: 0,
          unreadNotifications: 0,
          todayNotifications: 0,
          notificationsByType: {},
        );
      }

      return NotificationStats.fromFirestore(doc);
    } catch (e) {
      appLogger.e('Error fetching notification stats', error: e);
      rethrow;
    }
  }

  /// Stream notification statistics
  Stream<NotificationStats> streamNotificationStats(String userId) {
    return _firestore
        .collection(_statsCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return NotificationStats(
              userId: userId,
              totalNotifications: 0,
              unreadNotifications: 0,
              todayNotifications: 0,
              notificationsByType: {},
            );
          }
          return NotificationStats.fromFirestore(doc);
        });
  }

  /// Get notification preferences
  Future<NotificationPreferences> getPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection(_preferencesCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return NotificationPreferences(userId: userId);
      }

      return NotificationPreferences.fromFirestore(doc);
    } catch (e) {
      appLogger.e('Error fetching notification preferences', error: e);
      rethrow;
    }
  }

  /// Update notification preferences
  Future<void> updatePreferences(
    String userId,
    NotificationPreferences preferences,
  ) async {
    try {
      await _firestore
          .collection(_preferencesCollection)
          .doc(userId)
          .set(preferences.toFirestore(), SetOptions(merge: true));

      appLogger.d('Notification preferences updated for $userId');
    } catch (e) {
      appLogger.e('Error updating notification preferences', error: e);
      rethrow;
    }
  }

  /// Mute notifications for a facility
  Future<void> muteFacility(String userId, String facilityId) async {
    try {
      final prefs = await getPreferences(userId);
      final mutedIds = Set<String>.from(prefs.mutedFacilityIds)..add(facilityId);

      final updated = prefs.copyWith(
        mutedFacilityIds: mutedIds,
      );

      await updatePreferences(userId, updated);
    } catch (e) {
      appLogger.e('Error muting facility', error: e);
      rethrow;
    }
  }

  /// Unmute notifications for a facility
  Future<void> unmuteFacility(String userId, String facilityId) async {
    try {
      final prefs = await getPreferences(userId);
      final mutedIds = Set<String>.from(prefs.mutedFacilityIds)
          ..remove(facilityId);

      final updated = prefs.copyWith(
        mutedFacilityIds: mutedIds,
      );

      await updatePreferences(userId, updated);
    } catch (e) {
      appLogger.e('Error unmuting facility', error: e);
      rethrow;
    }
  }

  /// Check if should send notification based on preferences
  Future<bool> shouldSendNotification(
    String userId,
    NotificationType type, {
    String? facilityId,
  }) async {
    try {
      final prefs = await getPreferences(userId);

      // Check if facility is muted
      if (facilityId != null && prefs.mutedFacilityIds.contains(facilityId)) {
        return false;
      }

      // Check notification type preference
      switch (type) {
        case NotificationType.facilityUpdate:
          return prefs.enableFacilityUpdates;
        case NotificationType.newReview:
          return prefs.enableReviews;
        case NotificationType.reviewLike:
          return prefs.enableLikes;
        case NotificationType.community:
          return prefs.enableCommunity;
        case NotificationType.announcement:
          return prefs.enableAnnouncements;
        case NotificationType.promotion:
          return prefs.enablePromotions;
        case NotificationType.favoriteFacility:
          return prefs.enableFacilityUpdates;
        case NotificationType.localQA:
          return prefs.enableCommunity;
      }
    } catch (e) {
      appLogger.e('Error checking notification preference', error: e);
      return false;
    }
  }

  /// Clean up old notifications (runs periodically)
  Future<void> cleanupExpiredNotifications(String userId) async {
    try {
      final cutoffDate = DateTime.now().subtract(_notificationExpiry);

      final expiredDocs = await _firestore
          .collection(_notificationsCollection)
          .doc(userId)
          .collection('messages')
          .where('expiresAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      appLogger.d('Cleaned up ${expiredDocs.size} expired notifications for $userId');
    } catch (e) {
      appLogger.e('Error cleaning up expired notifications', error: e);
      rethrow;
    }
  }

  /// Update notification statistics
  Future<void> _updateNotificationStats(
    String userId,
    NotificationType type,
  ) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final stats = await getNotificationStats(userId);
      final typeCount = Map<NotificationType, int>.from(stats.notificationsByType);
      typeCount[type] = (typeCount[type] ?? 0) + 1;

      final todayNotifications = await _firestore
          .collection(_notificationsCollection)
          .doc(userId)
          .collection('messages')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .count()
          .get();

      final updated = NotificationStats(
        userId: userId,
        totalNotifications: stats.totalNotifications + 1,
        unreadNotifications: stats.unreadNotifications + 1,
        todayNotifications: todayNotifications.count ?? 0,
        notificationsByType: typeCount,
        lastNotificationAt: DateTime.now(),
      );

      await _firestore
          .collection(_statsCollection)
          .doc(userId)
          .set(updated.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      appLogger.e('Error updating notification stats', error: e);
    }
  }

  /// Update unread notification count
  Future<void> _updateUnreadCount(String userId) async {
    try {
      final unreadCount = await _firestore
          .collection(_notificationsCollection)
          .doc(userId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      await _firestore
          .collection(_statsCollection)
          .doc(userId)
          .update({
            'unreadNotifications': unreadCount.count ?? 0,
          });
    } catch (e) {
      appLogger.e('Error updating unread count', error: e);
    }
  }
}
