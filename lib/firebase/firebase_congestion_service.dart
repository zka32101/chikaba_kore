import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/congestion_report.dart';
import '../services/congestion_service.dart';

/// 混雑状況の鮮度窓（この時間より古い投稿は集計対象外。実況性を重視するため短めに設定）。
const congestionFreshnessWindow = Duration(minutes: 30);

/// 集計に使う直近投稿の最大件数。
const _recentReportsLimit = 5;

/// 時間帯別パターンの集計対象期間（直近分の投稿のみを対象にする）。
const _hourlyPatternWindow = Duration(days: 30);

/// 時間帯別パターン集計時に取得する投稿の最大件数。
const _hourlyPatternFetchLimit = 500;

/// 混雑度合いをスコア化（0.0=空いてる 〜 1.0=混んでる）。
double _scoreOf(CongestionLevel level) => switch (level) {
      CongestionLevel.empty => 0.0,
      CongestionLevel.normal => 0.5,
      CongestionLevel.crowded => 1.0,
    };

/// Firestoreの`congestionReports`から直近の投稿を集計する実装。投稿自体は
/// `submitCongestionReport`Callable Function経由で行う（firestore.rulesで
/// クライアントからの直接書き込みを禁止しているため、サーバー側でレート制限を適用できる）。
class FirestoreCongestionService implements CongestionService {
  FirestoreCongestionService(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Future<CongestionStatus> fetchStatus(String facilityId) async {
    final since = DateTime.now().subtract(congestionFreshnessWindow);
    final snapshot = await _firestore
        .collection('congestionReports')
        .where('facilityId', isEqualTo: facilityId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: true)
        .limit(_recentReportsLimit)
        .get();

    final reports = snapshot.docs
        .map((doc) {
          final data = doc.data();
          final level = CongestionLevel.fromName(data['level'] as String?);
          final createdAt = data['createdAt'];
          if (level == null || createdAt is! Timestamp) return null;
          return CongestionReport(
            id: doc.id,
            facilityId: facilityId,
            level: level,
            createdAt: createdAt.toDate(),
          );
        })
        .whereType<CongestionReport>()
        .toList();

    if (reports.isEmpty) return CongestionStatus.empty;

    final counts = <CongestionLevel, int>{};
    for (final report in reports) {
      counts[report.level] = (counts[report.level] ?? 0) + 1;
    }
    final mostReported = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return CongestionStatus(
      level: mostReported,
      reportCount: reports.length,
      latestReportAt: reports.first.createdAt,
    );
  }

  @override
  Future<void> submitReport(String facilityId, CongestionLevel level) async {
    final callable = _functions.httpsCallable('submitCongestionReport');
    await callable.call({'facilityId': facilityId, 'level': level.name});
  }

  @override
  Future<CongestionHourlyPattern> fetchHourlyPattern(String facilityId) async {
    final since = DateTime.now().subtract(_hourlyPatternWindow);
    final snapshot = await _firestore
        .collection('congestionReports')
        .where('facilityId', isEqualTo: facilityId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: true)
        .limit(_hourlyPatternFetchLimit)
        .get();

    final sumByHour = <int, double>{};
    final countByHour = <int, int>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final level = CongestionLevel.fromName(data['level'] as String?);
      final createdAt = data['createdAt'];
      if (level == null || createdAt is! Timestamp) continue;
      final hour = createdAt.toDate().hour;
      sumByHour[hour] = (sumByHour[hour] ?? 0) + _scoreOf(level);
      countByHour[hour] = (countByHour[hour] ?? 0) + 1;
    }

    final averages = {
      for (final hour in countByHour.keys) hour: sumByHour[hour]! / countByHour[hour]!,
    };
    final total = countByHour.values.fold<int>(0, (sum, c) => sum + c);

    return CongestionHourlyPattern(averageScoreByHour: averages, totalReportCount: total);
  }
}
