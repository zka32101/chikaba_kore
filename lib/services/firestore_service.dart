import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/facility_model.dart';
import '../models/review_model.dart';
import '../models/favorite_model.dart';
import '../utils/logger.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---- Facilities ----

  Future<List<FacilityModel>> getFacilitiesByCategory(
    String category, {
    int limit = 20,
    int offset = 0,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query query = _db
          .collection('facilities')
          .where('category', isEqualTo: category)
          .orderBy('averageRating', descending: true)
          .limit(limit);
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      } else if (offset > 0) {
        // offset 件分スキップしてカーソルを取得
        final skipSnap = await _db
            .collection('facilities')
            .where('category', isEqualTo: category)
            .orderBy('averageRating', descending: true)
            .limit(offset)
            .get();
        if (skipSnap.docs.isNotEmpty) {
          query = query.startAfterDocument(skipSnap.docs.last);
        }
      }
      final snapshot = await query.get();
      return snapshot.docs.map(FacilityModel.fromFirestore).toList();
    } catch (e) {
      appLogger.e('getFacilitiesByCategory error', error: e);
      rethrow;
    }
  }

  Future<List<FacilityModel>> getNearbyFacilities({
    required double lat,
    required double lng,
    double radiusKm = 2.0,
    String? category,
    int limit = 30,
  }) async {
    // GeoQuery は geohash 実装が必要なため、簡易的な bounding box フィルタリング
    final latDelta = radiusKm / 111.0;
    final lngDelta = radiusKm / (111.0 * 0.7);
    try {
      Query query = _db.collection('facilities');
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      // Firestore は複合不等式が1フィールドのみのため、lat のみでフィルタ
      final snapshot = await query
          .where('latitude', isGreaterThan: lat - latDelta)
          .where('latitude', isLessThan: lat + latDelta)
          .limit(limit)
          .get();
      return snapshot.docs
          .map(FacilityModel.fromFirestore)
          .where((f) => (f.longitude - lng).abs() < lngDelta)
          .toList();
    } catch (e) {
      appLogger.e('getNearbyFacilities error', error: e);
      rethrow;
    }
  }

  Future<FacilityModel?> getFacility(String facilityId) async {
    final doc = await _db.collection('facilities').doc(facilityId).get();
    if (!doc.exists) return null;
    return FacilityModel.fromFirestore(doc);
  }

  // ---- Reviews ----

  Future<List<ReviewModel>> getReviews(
    String facilityId, {
    int limit = 10,
    DocumentSnapshot? lastDoc,
  }) async {
    Query query = _db
        .collection('reviews')
        .where('facilityId', isEqualTo: facilityId)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (lastDoc != null) query = query.startAfterDocument(lastDoc);
    final snapshot = await query.get();
    return snapshot.docs.map(ReviewModel.fromFirestore).toList();
  }

  Future<void> addReview(ReviewModel review) async {
    final batch = _db.batch();
    final reviewRef = _db.collection('reviews').doc();
    batch.set(reviewRef, review.toFirestore());
    // averageRating の更新はCloud Functions に委譲
    await batch.commit();
  }

  // ---- Favorites ----

  Stream<List<FavoriteModel>> watchFavorites(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(FavoriteModel.fromFirestore).toList());
  }

  Future<void> addFavorite(String userId, FavoriteModel favorite) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(favorite.facilityId)
        .set(favorite.toFirestore());
  }

  Future<void> removeFavorite(String userId, String facilityId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(facilityId)
        .delete();
  }

  Future<void> updateFavoriteStatus(
    String userId,
    String facilityId,
    FavoriteStatus status,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(facilityId)
        .update({'status': status == FavoriteStatus.willGo ? 'will_go' : 'want_to_go'});
  }

  Future<void> updateFavoriteMemo(
    String userId,
    String facilityId,
    String memo,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(facilityId)
        .update({'memo': memo});
  }


  Future<List<FacilityModel>> searchFacilities({
    required String query,
    String? category,
    bool openNowOnly = false,
    int limit = 30,
  }) async {
    try {
      Query q = _db.collection('facilities');
      if (category != null) {
        q = q.where('category', isEqualTo: category);
      }
      if (query.isNotEmpty) {
        // Firestore の前方一致検索（name フィールド）
        q = q
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThan: '$query');
      }
      q = q.limit(limit);
      final snapshot = await q.get();
      var results = snapshot.docs.map(FacilityModel.fromFirestore).toList();
      if (openNowOnly) {
        results = results.where((f) => f.isOpenNow).toList();
      }
      return results;
    } catch (e) {
      appLogger.e('searchFacilities error', error: e);
      rethrow;
    }
  }

  /// ガチャ用：フィルタなしで全施設を取得（最大500件）
  Future<List<FacilityModel>> getAllFacilities({int limit = 500}) async {
    try {
      final snapshot = await _db
          .collection('facilities')
          .limit(limit)
          .get();
      return snapshot.docs.map(FacilityModel.fromFirestore).toList();
    } catch (e) {
      appLogger.e('getAllFacilities error', error: e);
      rethrow;
    }
  }

  Future<bool> isFavorite(String userId, String facilityId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(facilityId)
        .get();
    return doc.exists;
  }
}
