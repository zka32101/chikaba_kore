import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics_model.dart';
import '../utils/logger.dart';

class AnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Track a user event
  Future<void> trackEvent(
    String eventName,
    String userId, {
    Map<String, dynamic>? properties,
    String? sessionId,
    String? screen,
  }) async {
    try {
      final event = AnalyticsEvent(
        id: _db.collection('analytics_events').doc().id,
        eventName: eventName,
        userId: userId,
        properties: properties ?? {},
        timestamp: DateTime.now(),
        sessionId: sessionId,
        screen: screen,
      );

      await _db
          .collection('analytics_events')
          .doc(event.id)
          .set(event.toFirestore());

      appLogger.d('Event tracked: $eventName by $userId');
    } catch (e) {
      appLogger.e('Error tracking event: $eventName', error: e);
      rethrow;
    }
  }

  /// Get platform-wide analytics summary
  Future<AnalyticsSummary?> getAnalyticsSummary() async {
    try {
      final doc = await _db.collection('analytics_summary').doc('current').get();
      if (!doc.exists) return null;
      return AnalyticsSummary.fromFirestore(doc);
    } catch (e) {
      appLogger.e('Error fetching analytics summary', error: e);
      rethrow;
    }
  }

  /// Get user activity metrics
  Future<UserActivityMetrics?> getUserActivityMetrics(String userId) async {
    try {
      final doc = await _db.collection('user_analytics').doc(userId).get();
      if (!doc.exists) return null;
      return UserActivityMetrics.fromFirestore(doc);
    } catch (e) {
      appLogger.e('Error fetching user activity metrics', error: e);
      rethrow;
    }
  }

  /// Update user activity metrics
  Future<void> updateUserActivityMetrics(
    String userId, {
    int? facilitiesSearched,
    int? reviewsCreated,
    int? favoritesAdded,
  }) async {
    try {
      final updates = <String, dynamic>{
        'lastActiveAt': Timestamp.now(),
      };

      if (facilitiesSearched != null) {
        updates['facilitiesSearched'] = FieldValue.increment(facilitiesSearched);
      }
      if (reviewsCreated != null) {
        updates['reviewsCreated'] = FieldValue.increment(reviewsCreated);
      }
      if (favoritesAdded != null) {
        updates['favoritesAdded'] = FieldValue.increment(favoritesAdded);
      }

      await _db.collection('user_analytics').doc(userId).update(updates);
      appLogger.d('User activity metrics updated for $userId');
    } catch (e) {
      appLogger.e('Error updating user activity metrics', error: e);
      rethrow;
    }
  }

  /// Get facility analytics
  Future<FacilityAnalytics?> getFacilityAnalytics(String facilityId) async {
    try {
      final doc = await _db.collection('facility_analytics').doc(facilityId).get();
      if (!doc.exists) return null;
      return FacilityAnalytics.fromFirestore(doc);
    } catch (e) {
      appLogger.e('Error fetching facility analytics', error: e);
      rethrow;
    }
  }

  /// Track facility view
  Future<void> trackFacilityView(String facilityId, String userId) async {
    try {
      await _db.collection('facility_analytics').doc(facilityId).update({
        'totalViews': FieldValue.increment(1),
        'lastViewedAt': Timestamp.now(),
      });

      await trackEvent(
        'facility_viewed',
        userId,
        properties: {'facilityId': facilityId},
      );

      appLogger.d('Facility view tracked for $facilityId');
    } catch (e) {
      appLogger.e('Error tracking facility view', error: e);
      rethrow;
    }
  }

  /// Track review creation
  Future<void> trackReviewCreation(String facilityId, String userId) async {
    try {
      await _db.collection('facility_analytics').doc(facilityId).update({
        'totalReviews': FieldValue.increment(1),
        'reviewsThisMonth': FieldValue.increment(1),
      });

      await trackEvent(
        'review_created',
        userId,
        properties: {'facilityId': facilityId},
      );

      appLogger.d('Review creation tracked for $facilityId');
    } catch (e) {
      appLogger.e('Error tracking review creation', error: e);
      rethrow;
    }
  }

  /// Track favorite action
  Future<void> trackFavoriteAction(
    String facilityId,
    String userId,
    String actionType,
  ) async {
    try {
      if (actionType == 'add') {
        await _db.collection('facility_analytics').doc(facilityId).update({
          'totalFavorites': FieldValue.increment(1),
        });
      } else if (actionType == 'remove') {
        await _db.collection('facility_analytics').doc(facilityId).update({
          'totalFavorites': FieldValue.increment(-1),
        });
      }

      await trackEvent(
        'favorite_$actionType',
        userId,
        properties: {'facilityId': facilityId},
      );

      appLogger.d('Favorite action tracked: $actionType for $facilityId');
    } catch (e) {
      appLogger.e('Error tracking favorite action', error: e);
      rethrow;
    }
  }

  /// Get events for a user in a date range
  Future<List<AnalyticsEvent>> getUserEvents(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _db
          .collection('analytics_events')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      return snapshot.docs.map(AnalyticsEvent.fromFirestore).toList();
    } catch (e) {
      appLogger.e('Error fetching user events', error: e);
      rethrow;
    }
  }

  /// Get event counts by type
  Future<Map<String, int>> getEventCounts({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _db.collection('analytics_events');

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      final Map<String, int> counts = {};

      for (final doc in snapshot.docs) {
        final eventName = doc['eventName'] as String;
        counts[eventName] = (counts[eventName] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      appLogger.e('Error fetching event counts', error: e);
      rethrow;
    }
  }

  /// Get top facilities by views
  Future<List<FacilityAnalytics>> getTopFacilitiesByViews({
    int limit = 10,
  }) async {
    try {
      final snapshot = await _db
          .collection('facility_analytics')
          .orderBy('totalViews', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(FacilityAnalytics.fromFirestore).toList();
    } catch (e) {
      appLogger.e('Error fetching top facilities by views', error: e);
      rethrow;
    }
  }

  /// Get top facilities by reviews
  Future<List<FacilityAnalytics>> getTopFacilitiesByReviews({
    int limit = 10,
  }) async {
    try {
      final snapshot = await _db
          .collection('facility_analytics')
          .orderBy('totalReviews', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(FacilityAnalytics.fromFirestore).toList();
    } catch (e) {
      appLogger.e('Error fetching top facilities by reviews', error: e);
      rethrow;
    }
  }

  /// Get cohort analysis data
  Future<CohortAnalysis?> getCohortAnalysis(String cohortId) async {
    try {
      final doc = await _db.collection('cohort_analysis').doc(cohortId).get();
      if (!doc.exists) return null;
      return CohortAnalysis.fromFirestore(doc);
    } catch (e) {
      appLogger.e('Error fetching cohort analysis', error: e);
      rethrow;
    }
  }

  /// Get all cohorts
  Future<List<CohortAnalysis>> getAllCohorts() async {
    try {
      final snapshot = await _db
          .collection('cohort_analysis')
          .orderBy('cohortDate', descending: true)
          .get();

      return snapshot.docs.map(CohortAnalysis.fromFirestore).toList();
    } catch (e) {
      appLogger.e('Error fetching cohorts', error: e);
      rethrow;
    }
  }

  /// Stream analytics summary updates in real-time
  Stream<AnalyticsSummary?> streamAnalyticsSummary() {
    return _db.collection('analytics_summary').doc('current').snapshots().map(
      (doc) {
        if (!doc.exists) return null;
        return AnalyticsSummary.fromFirestore(doc);
      },
    );
  }

  /// Stream user activity updates in real-time
  Stream<UserActivityMetrics?> streamUserActivity(String userId) {
    return _db.collection('user_analytics').doc(userId).snapshots().map(
      (doc) {
        if (!doc.exists) return null;
        return UserActivityMetrics.fromFirestore(doc);
      },
    );
  }

  /// Stream facility analytics updates in real-time
  Stream<FacilityAnalytics?> streamFacilityAnalytics(String facilityId) {
    return _db.collection('facility_analytics').doc(facilityId).snapshots().map(
      (doc) {
        if (!doc.exists) return null;
        return FacilityAnalytics.fromFirestore(doc);
      },
    );
  }
}
