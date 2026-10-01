/// 施設の「今の混雑状況」投稿（3段階）。
enum CongestionLevel {
  empty,
  normal,
  crowded;

  String get label {
    switch (this) {
      case CongestionLevel.empty:
        return '空いてる';
      case CongestionLevel.normal:
        return '普通';
      case CongestionLevel.crowded:
        return '混んでる';
    }
  }

  static CongestionLevel? fromName(String? name) {
    for (final level in CongestionLevel.values) {
      if (level.name == name) return level;
    }
    return null;
  }
}

/// 個々の混雑状況投稿。
class CongestionReport {
  const CongestionReport({
    required this.id,
    required this.facilityId,
    required this.level,
    required this.createdAt,
  });

  final String id;
  final String facilityId;
  final CongestionLevel level;
  final DateTime createdAt;
}

/// 施設詳細画面に表示する、直近の投稿から集計した混雑状況。
/// `level`がnullの場合は直近の投稿が無く情報なし。
class CongestionStatus {
  const CongestionStatus({
    required this.level,
    required this.reportCount,
    this.latestReportAt,
  });

  final CongestionLevel? level;
  final int reportCount;
  final DateTime? latestReportAt;

  static const empty = CongestionStatus(level: null, reportCount: 0);
}
