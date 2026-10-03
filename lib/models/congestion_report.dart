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

/// 時間帯(0-23時)ごとに集計した混雑度パターン。「混みやすい時間帯」の
/// ヒートマップ表示に使う。
class CongestionHourlyPattern {
  const CongestionHourlyPattern({
    required this.averageScoreByHour,
    required this.totalReportCount,
  });

  /// 時間帯(0-23)ごとの平均混雑度（0.0=空いてる 〜 1.0=混んでる）。
  /// 投稿が無い時間帯はキーが存在しない。
  final Map<int, double> averageScoreByHour;

  /// 集計対象期間内の投稿総数。
  final int totalReportCount;

  static const empty = CongestionHourlyPattern(averageScoreByHour: {}, totalReportCount: 0);

  /// ヒートマップとして意味のある傾向を示すのに十分な投稿数があるか。
  bool get hasEnoughData => totalReportCount >= 5;
}
