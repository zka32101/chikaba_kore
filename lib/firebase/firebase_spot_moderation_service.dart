import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/pending_spot.dart';
import '../services/spot_moderation_service.dart';
import '../services/spot_vote_service.dart' show SpotVoteKind;

const _shadeTypeLabels = {
  'tree': '木陰',
  'arcade': 'アーケード',
  'rain_shelter': '雨よけ',
};

const _brightnessReasonLabels = {
  'dark': '夜の明るさ',
  'low_foot_traffic': '人通りが少ない',
};

/// `shadeSpots`/`brightnessSpots`のfirestore.rulesは`allow update, delete: if false`で
/// クライアントからの直接更新を一切禁止しているため、承認/却下は`moderateSpot`
/// Callable Function（管理者のみ実行可、Admin SDK経由でルールの制約を受けない）を呼ぶ。
class FirestoreSpotModerationService implements SpotModerationService {
  FirestoreSpotModerationService(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Future<List<PendingSpot>> fetchPending({int limit = 50}) async {
    final results = await Future.wait([
      _fetchCollection('shadeSpots', SpotVoteKind.shade, limit),
      _fetchCollection('brightnessSpots', SpotVoteKind.brightness, limit),
    ]);

    final merged = [...results[0], ...results[1]]
      ..sort((a, b) {
        final aTime = a.createdAt;
        final bTime = b.createdAt;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

    return merged.take(limit).toList();
  }

  Future<List<PendingSpot>> _fetchCollection(String collection, SpotVoteKind kind, int limit) async {
    final snapshot = await _firestore
        .collection(collection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final createdAt = data['createdAt'];
      final label = kind == SpotVoteKind.shade
          ? _shadeTypeLabels[data['type']] ?? '投稿'
          : _brightnessReasonLabels[data['reasonType']] ?? '投稿';
      return PendingSpot(
        id: doc.id,
        kind: kind,
        label: label,
        submitterId: data['submitterId'] as String? ?? '',
        createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      );
    }).toList();
  }

  @override
  Future<void> approve(SpotVoteKind kind, String spotId) => _moderate(kind, spotId, 'approve');

  @override
  Future<void> reject(SpotVoteKind kind, String spotId) => _moderate(kind, spotId, 'reject');

  Future<void> _moderate(SpotVoteKind kind, String spotId, String action) async {
    final callable = _functions.httpsCallable('moderateSpot');
    await callable.call({
      'spotKind': kind == SpotVoteKind.shade ? 'shade' : 'brightness',
      'spotId': spotId,
      'action': action,
    });
  }
}
