import 'package:cloud_firestore/cloud_firestore.dart';

/// Analytics event for tracking user interactions
class AnalyticsEvent {
  final String id;
  final String eventName;
  final String userId;
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  final String? sessionId;
  final String? screen;

  const AnalyticsEvent({
    required this.id,
    required this.eventName,
    required this.userId,
    required this.properties,
    required this.timestamp,
    this.sessionId,
    this.screen,
  });

  factory AnalyticsEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnalyticsEvent(
      id: doc.id,
      eventName: data['eventName'] as String,
      userId: data['userId'] as String,
      properties: Map<String, dynamic>.from(data['properties'] as Map? ?? {}),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      sessionId: data['sessionId'] as String?,
      screen: data['screen'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'eventName': eventName,
        'userId': userId,
        'properties': properties,
        'timestamp': Timestamp.fromDate(timestamp),
        'sessionId': sessionId,
        'screen': screen,
      };
}

/// User activity metrics
class UserActivityMetrics {
  final String userId;
  final int totalSessions;
  final Duration totalSessionTime;
  final DateTime lastActiveAt;
  final int facilitiesSearched;
  final int reviewsCreated;
  final int favoritesAdded;
  final List<String> topCategories;
  final DateTime? createdAt;

  const UserActivityMetrics({
    required this.userId,
    required this.totalSessions,
    required this.totalSessionTime,
    required this.lastActiveAt,
    required this.facilitiesSearched,
    required this.reviewsCreated,
    required this.favoritesAdded,
    required this.topCategories,
    this.createdAt,
  });

  factory UserActivityMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserActivityMetrics(
      userId: doc.id,
      totalSessions: data['totalSessions'] as int? ?? 0,
      totalSessionTime: Duration(
        seconds: data['totalSessionTimeSeconds'] as int? ?? 0,
      ),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      facilitiesSearched: data['facilitiesSearched'] as int? ?? 0,
      reviewsCreated: data['reviewsCreated'] as int? ?? 0,
      favoritesAdded: data['favoritesAdded'] as int? ?? 0,
      topCategories: List<String>.from(data['topCategories'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'totalSessions': totalSessions,
        'totalSessionTimeSeconds': totalSessionTime.inSeconds,
        'lastActiveAt': Timestamp.fromDate(lastActiveAt),
        'facilitiesSearched': facilitiesSearched,
        'reviewsCreated': reviewsCreated,
        'favoritesAdded': favoritesAdded,
        'topCategories': topCategories,
        'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
      };
}

/// Facility popularity metrics
class FacilityAnalytics {
  final String facilityId;
  final int totalViews;
  final int totalReviews;
  final int totalFavorites;
  final double averageRating;
  final List<String> topReviewAuthors;
  final DateTime lastViewedAt;
  final int viewsThisWeek;
  final int reviewsThisMonth;

  const FacilityAnalytics({
    required this.facilityId,
    required this.totalViews,
    required this.totalReviews,
    required this.totalFavorites,
    required this.averageRating,
    required this.topReviewAuthors,
    required this.lastViewedAt,
    required this.viewsThisWeek,
    required this.reviewsThisMonth,
  });

  factory FacilityAnalytics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FacilityAnalytics(
      facilityId: doc.id,
      totalViews: data['totalViews'] as int? ?? 0,
      totalReviews: data['totalReviews'] as int? ?? 0,
      totalFavorites: data['totalFavorites'] as int? ?? 0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      topReviewAuthors: List<String>.from(data['topReviewAuthors'] as List? ?? []),
      lastViewedAt: (data['lastViewedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewsThisWeek: data['viewsThisWeek'] as int? ?? 0,
      reviewsThisMonth: data['reviewsThisMonth'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'totalViews': totalViews,
        'totalReviews': totalReviews,
        'totalFavorites': totalFavorites,
        'averageRating': averageRating,
        'topReviewAuthors': topReviewAuthors,
        'lastViewedAt': Timestamp.fromDate(lastViewedAt),
        'viewsThisWeek': viewsThisWeek,
        'reviewsThisMonth': reviewsThisMonth,
      };
}

/// Platform-wide analytics summary
class AnalyticsSummary {
  final int totalUsers;
  final int activeUsersToday;
  final int activeUsersThisWeek;
  final int totalFacilities;
  final int totalReviews;
  final double averagePlatformRating;
  final int sessionsToday;
  final Duration averageSessionDuration;
  final List<String> topFacilityCategories;
  final Map<String, int> eventCounts;

  const AnalyticsSummary({
    required this.totalUsers,
    required this.activeUsersToday,
    required this.activeUsersThisWeek,
    required this.totalFacilities,
    required this.totalReviews,
    required this.averagePlatformRating,
    required this.sessionsToday,
    required this.averageSessionDuration,
    required this.topFacilityCategories,
    required this.eventCounts,
  });

  factory AnalyticsSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnalyticsSummary(
      totalUsers: data['totalUsers'] as int? ?? 0,
      activeUsersToday: data['activeUsersToday'] as int? ?? 0,
      activeUsersThisWeek: data['activeUsersThisWeek'] as int? ?? 0,
      totalFacilities: data['totalFacilities'] as int? ?? 0,
      totalReviews: data['totalReviews'] as int? ?? 0,
      averagePlatformRating: (data['averagePlatformRating'] as num?)?.toDouble() ?? 0.0,
      sessionsToday: data['sessionsToday'] as int? ?? 0,
      averageSessionDuration: Duration(
        seconds: data['averageSessionDurationSeconds'] as int? ?? 0,
      ),
      topFacilityCategories: List<String>.from(data['topFacilityCategories'] as List? ?? []),
      eventCounts: Map<String, int>.from(data['eventCounts'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'totalUsers': totalUsers,
        'activeUsersToday': activeUsersToday,
        'activeUsersThisWeek': activeUsersThisWeek,
        'totalFacilities': totalFacilities,
        'totalReviews': totalReviews,
        'averagePlatformRating': averagePlatformRating,
        'sessionsToday': sessionsToday,
        'averageSessionDurationSeconds': averageSessionDuration.inSeconds,
        'topFacilityCategories': topFacilityCategories,
        'eventCounts': eventCounts,
      };
}

/// Time series data point for metrics charts
class AnalyticsDataPoint {
  final DateTime timestamp;
  final double value;
  final String label;
  final Map<String, dynamic> metadata;

  const AnalyticsDataPoint({
    required this.timestamp,
    required this.value,
    required this.label,
    this.metadata = const {},
  });

  factory AnalyticsDataPoint.fromMap(Map<String, dynamic> map) {
    return AnalyticsDataPoint(
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      value: (map['value'] as num).toDouble(),
      label: map['label'] as String,
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'timestamp': Timestamp.fromDate(timestamp),
        'value': value,
        'label': label,
        'metadata': metadata,
      };
}

/// Cohort analysis data
class CohortAnalysis {
  final String cohortId;
  final DateTime cohortDate;
  final int cohortSize;
  final Map<String, double> retentionByDay;
  final double day1Retention;
  final double day7Retention;
  final double day30Retention;

  const CohortAnalysis({
    required this.cohortId,
    required this.cohortDate,
    required this.cohortSize,
    required this.retentionByDay,
    required this.day1Retention,
    required this.day7Retention,
    required this.day30Retention,
  });

  factory CohortAnalysis.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CohortAnalysis(
      cohortId: doc.id,
      cohortDate: (data['cohortDate'] as Timestamp).toDate(),
      cohortSize: data['cohortSize'] as int? ?? 0,
      retentionByDay: Map<String, double>.from(
        (data['retentionByDay'] as Map? ?? {}).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      ),
      day1Retention: (data['day1Retention'] as num?)?.toDouble() ?? 0.0,
      day7Retention: (data['day7Retention'] as num?)?.toDouble() ?? 0.0,
      day30Retention: (data['day30Retention'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'cohortDate': Timestamp.fromDate(cohortDate),
        'cohortSize': cohortSize,
        'retentionByDay': retentionByDay,
        'day1Retention': day1Retention,
        'day7Retention': day7Retention,
        'day30Retention': day30Retention,
      };
}
