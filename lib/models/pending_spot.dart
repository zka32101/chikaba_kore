import '../services/spot_vote_service.dart' show SpotVoteKind;

/// 承認待ち（`status == 'pending'`）の投稿（`shadeSpots`/`brightnessSpots`）。
/// 管理者向け承認画面で表示する最小限の情報のみを持つ（`SpotSummary`と同様の
/// プライバシー設計方針、生の緯度経度は含めない）。
class PendingSpot {
  const PendingSpot({
    required this.id,
    required this.kind,
    required this.label,
    required this.submitterId,
    this.createdAt,
  });

  final String id;
  final SpotVoteKind kind;

  /// 投稿種別の表示名（例:「木陰」「夜の明るさ」）。
  final String label;

  final String submitterId;
  final DateTime? createdAt;
}
