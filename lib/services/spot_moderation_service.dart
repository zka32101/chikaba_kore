import '../models/pending_spot.dart';
import 'spot_vote_service.dart' show SpotVoteKind;

/// 投稿（shadeSpots/brightnessSpots）の人力承認/却下の抽象インターフェース。
/// `ReviewRepository`の承認待ちクチコミと同じ「取得＋承認/却下」の構成を踏襲している。
abstract class SpotModerationService {
  /// 承認待ち（`status == 'pending'`）の投稿を新着順に返す（`shadeSpots`/`brightnessSpots`横断）。
  Future<List<PendingSpot>> fetchPending({int limit = 50});

  Future<void> approve(SpotVoteKind kind, String spotId);

  Future<void> reject(SpotVoteKind kind, String spotId);
}

/// Firebase未接続環境向けのフォールバック実装。常に空リストを返す。
class LocalSpotModerationService implements SpotModerationService {
  @override
  Future<List<PendingSpot>> fetchPending({int limit = 50}) async => const [];

  @override
  Future<void> approve(SpotVoteKind kind, String spotId) async {}

  @override
  Future<void> reject(SpotVoteKind kind, String spotId) async {}
}
