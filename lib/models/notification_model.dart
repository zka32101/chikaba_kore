import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification types
enum NotificationType {
  facilityUpdate,      // 施設の更新（営業時間変更など）
  newReview,          // 施設にレビューが追加
  reviewLike,         // 自分のレビューにいいねが付いた
  favoriteFacility,   // お気に入り施設の新情報
  localQA,            // ローカルQ&Aの回答
  community,          // コミュニティ通知
  announcement,       // 一般お知らせ
  promotion,          // キャンペーン・プロモーション
}

/// Notification priority levels
enum NotificationPriority {
  low,
  normal,
  high,
}

/// User notification preferences
class NotificationPreferences {
  final String userId;
  final bool enableFacilityUpdates;
  final bool enableReviews;
  final bool enableLikes;
  final bool enableCommunity;
  final bool enableAnnouncements;
  final bool enablePromotions;
  final bool enableSoundNotifications;
  final bool enableVibration;
  final bool batchNotifications;
  final int batchWindowMinutes;      // バッチ送信の時間窓（分）
  final Set<String> mutedFacilityIds; // ミュート対象施設
  final DateTime? quietHoursStart;   // 静かな時間帯の開始
  final DateTime? quietHoursEnd;     // 静かな時間帯の終了
  final DateTime? lastUpdatedAt;

  const NotificationPreferences({
    required this.userId,
    this.enableFacilityUpdates = true,
    this.enableReviews = true,
    this.enableLikes = true,
    this.enableCommunity = true,
    this.enableAnnouncements = true,
    this.enablePromotions = false,
    this.enableSoundNotifications = true,
    this.enableVibration = true,
    this.batchNotifications = true,
    this.batchWindowMinutes = 30,
    this.mutedFacilityIds = const {},
    this.quietHoursStart,
    this.quietHoursEnd,
    this.lastUpdatedAt,
  });

  factory NotificationPreferences.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationPreferences(
      userId: doc.id,
      enableFacilityUpdates: data['enableFacilityUpdates'] as bool? ?? true,
      enableReviews: data['enableReviews'] as bool? ?? true,
      enableLikes: data['enableLikes'] as bool? ?? true,
      enableCommunity: data['enableCommunity'] as bool? ?? true,
      enableAnnouncements: data['enableAnnouncements'] as bool? ?? true,
      enablePromotions: data['enablePromotions'] as bool? ?? false,
      enableSoundNotifications: data['enableSoundNotifications'] as bool? ?? true,
      enableVibration: data['enableVibration'] as bool? ?? true,
      batchNotifications: data['batchNotifications'] as bool? ?? true,
      batchWindowMinutes: data['batchWindowMinutes'] as int? ?? 30,
      mutedFacilityIds: Set<String>.from(
        data['mutedFacilityIds'] as List? ?? [],
      ),
      quietHoursStart: (data['quietHoursStart'] as Timestamp?)?.toDate(),
      quietHoursEnd: (data['quietHoursEnd'] as Timestamp?)?.toDate(),
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'enableFacilityUpdates': enableFacilityUpdates,
    'enableReviews': enableReviews,
    'enableLikes': enableLikes,
    'enableCommunity': enableCommunity,
    'enableAnnouncements': enableAnnouncements,
    'enablePromotions': enablePromotions,
    'enableSoundNotifications': enableSoundNotifications,
    'enableVibration': enableVibration,
    'batchNotifications': batchNotifications,
    'batchWindowMinutes': batchWindowMinutes,
    'mutedFacilityIds': mutedFacilityIds.toList(),
    'quietHoursStart': quietHoursStart != null ? Timestamp.fromDate(quietHoursStart!) : null,
    'quietHoursEnd': quietHoursEnd != null ? Timestamp.fromDate(quietHoursEnd!) : null,
    'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt ?? DateTime.now()),
  };
}

/// In-app notification (stored in Firestore)
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> metadata;  // facilityId, reviewId, etc.
  final DateTime timestamp;
  final bool isRead;
  final bool isArchived;
  final DateTime? readAt;
  final DateTime? expiresAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.title,
    required this.body,
    this.imageUrl,
    this.metadata = const {},
    required this.timestamp,
    this.isRead = false,
    this.isArchived = false,
    this.readAt,
    this.expiresAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] as String,
      type: NotificationType.values.byName(data['type'] as String? ?? 'announcement'),
      priority: NotificationPriority.values.byName(data['priority'] as String? ?? 'normal'),
      title: data['title'] as String,
      body: data['body'] as String,
      imageUrl: data['imageUrl'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] as bool? ?? false,
      isArchived: data['isArchived'] as bool? ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'type': type.name,
    'priority': priority.name,
    'title': title,
    'body': body,
    'imageUrl': imageUrl,
    'metadata': metadata,
    'timestamp': Timestamp.fromDate(timestamp),
    'isRead': isRead,
    'isArchived': isArchived,
    'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
  };

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    NotificationPriority? priority,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    bool? isRead,
    bool? isArchived,
    DateTime? readAt,
    DateTime? expiresAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      readAt: readAt ?? this.readAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

/// Notification statistics
class NotificationStats {
  final String userId;
  final int totalNotifications;
  final int unreadNotifications;
  final int todayNotifications;
  final Map<NotificationType, int> notificationsByType;
  final DateTime? lastNotificationAt;

  const NotificationStats({
    required this.userId,
    required this.totalNotifications,
    required this.unreadNotifications,
    required this.todayNotifications,
    required this.notificationsByType,
    this.lastNotificationAt,
  });

  factory NotificationStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final typeCountMap = (data['notificationsByType'] as Map? ?? {})
        .cast<String, int>();

    final notificationsByType = <NotificationType, int>{};
    for (final entry in typeCountMap.entries) {
      try {
        notificationsByType[NotificationType.values.byName(entry.key)] = entry.value;
      } catch (_) {
        // Ignore unknown types
      }
    }

    return NotificationStats(
      userId: doc.id,
      totalNotifications: data['totalNotifications'] as int? ?? 0,
      unreadNotifications: data['unreadNotifications'] as int? ?? 0,
      todayNotifications: data['todayNotifications'] as int? ?? 0,
      notificationsByType: notificationsByType,
      lastNotificationAt: (data['lastNotificationAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'totalNotifications': totalNotifications,
    'unreadNotifications': unreadNotifications,
    'todayNotifications': todayNotifications,
    'notificationsByType': notificationsByType
        .map((key, value) => MapEntry(key.name, value)),
    'lastNotificationAt': lastNotificationAt != null
        ? Timestamp.fromDate(lastNotificationAt!)
        : null,
  };
}
