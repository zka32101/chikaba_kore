import '../models/congestion_report.dart';

/// 施設の「今の混雑状況」投稿・取得の抽象インターフェース。
abstract class CongestionService {
  /// 直近の投稿から集計した混雑状況を取得する。
  Future<CongestionStatus> fetchStatus(String facilityId);

  /// 混雑状況を投稿する。
  Future<void> submitReport(String facilityId, CongestionLevel level);
}

/// Firebase未接続環境向けのフォールバック実装。常に情報なしを返す。
class LocalCongestionService implements CongestionService {
  @override
  Future<CongestionStatus> fetchStatus(String facilityId) async => CongestionStatus.empty;

  @override
  Future<void> submitReport(String facilityId, CongestionLevel level) async {}
}
