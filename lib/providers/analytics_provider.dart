import 'package:riverpod/riverpod.dart';
import '../models/analytics_model.dart';
import '../services/analytics_service.dart';

/// Analytics service provider
final analyticsServiceProvider = Provider((ref) => AnalyticsService());

/// Platform analytics summary provider
final analyticsSummaryProvider = FutureProvider.autoDispose((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getAnalyticsSummary();
});

/// Real-time analytics summary stream
final analyticsSummaryStreamProvider = StreamProvider.autoDispose((ref) {
  final service = ref.watch(analyticsServiceProvider);
  return service.streamAnalyticsSummary();
});

/// User activity metrics provider
final userActivityMetricsProvider =
    FutureProvider.autoDispose.family<UserActivityMetrics?, String>((ref, userId) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getUserActivityMetrics(userId);
});

/// Real-time user activity stream
final userActivityStreamProvider =
    StreamProvider.autoDispose.family<UserActivityMetrics?, String>((ref, userId) {
  final service = ref.watch(analyticsServiceProvider);
  return service.streamUserActivity(userId);
});

/// Facility analytics provider
final facilityAnalyticsProvider =
    FutureProvider.autoDispose.family<FacilityAnalytics?, String>((ref, facilityId) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getFacilityAnalytics(facilityId);
});

/// Real-time facility analytics stream
final facilityAnalyticsStreamProvider =
    StreamProvider.autoDispose.family<FacilityAnalytics?, String>((ref, facilityId) {
  final service = ref.watch(analyticsServiceProvider);
  return service.streamFacilityAnalytics(facilityId);
});

/// Top facilities by views provider
final topFacilitiesByViewsProvider =
    FutureProvider.autoDispose.family<List<FacilityAnalytics>, int>((ref, limit) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getTopFacilitiesByViews(limit: limit);
});

/// Top facilities by reviews provider
final topFacilitiesByReviewsProvider =
    FutureProvider.autoDispose.family<List<FacilityAnalytics>, int>((ref, limit) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getTopFacilitiesByReviews(limit: limit);
});

/// User events provider
final userEventsProvider = FutureProvider.autoDispose
    .family<List<AnalyticsEvent>, (String, DateTime?, DateTime?)>(
  (ref, params) async {
    final (userId, startDate, endDate) = params;
    final service = ref.watch(analyticsServiceProvider);
    return service.getUserEvents(userId, startDate: startDate, endDate: endDate);
  },
);

/// Event counts provider
final eventCountsProvider = FutureProvider.autoDispose
    .family<Map<String, int>, (DateTime?, DateTime?)>((ref, params) async {
  final (startDate, endDate) = params;
  final service = ref.watch(analyticsServiceProvider);
  return service.getEventCounts(startDate: startDate, endDate: endDate);
});

/// Cohort analysis provider
final cohortAnalysisProvider =
    FutureProvider.autoDispose.family<CohortAnalysis?, String>((ref, cohortId) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getCohortAnalysis(cohortId);
});

/// All cohorts provider
final allCohortsProvider = FutureProvider.autoDispose((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getAllCohorts();
});

/// Analytics period filter state
final analyticsPeriodProvider = StateProvider((ref) => AnalyticsPeriod.week);

/// Analytics selected facility provider
final selectedAnalyticsFacilityProvider = StateProvider<String?>((ref) => null);

enum AnalyticsPeriod {
  day,
  week,
  month,
  quarter,
  year,
  all,
}

extension AnalyticsPeriodExt on AnalyticsPeriod {
  String get label {
    switch (this) {
      case AnalyticsPeriod.day:
        return '24時間';
      case AnalyticsPeriod.week:
        return '週間';
      case AnalyticsPeriod.month:
        return '1ヶ月';
      case AnalyticsPeriod.quarter:
        return '四半期';
      case AnalyticsPeriod.year:
        return '1年';
      case AnalyticsPeriod.all:
        return 'すべて';
    }
  }

  Duration get duration {
    switch (this) {
      case AnalyticsPeriod.day:
        return const Duration(days: 1);
      case AnalyticsPeriod.week:
        return const Duration(days: 7);
      case AnalyticsPeriod.month:
        return const Duration(days: 30);
      case AnalyticsPeriod.quarter:
        return const Duration(days: 90);
      case AnalyticsPeriod.year:
        return const Duration(days: 365);
      case AnalyticsPeriod.all:
        return const Duration(days: 10000); // Very large duration
    }
  }

  (DateTime, DateTime) getDateRange() {
    final now = DateTime.now();
    final startDate = now.subtract(duration);
    return (startDate, now);
  }
}
