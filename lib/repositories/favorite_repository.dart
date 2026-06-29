import '../models/favorite_model.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

class FavoriteRepository {
  final FirestoreService _firestore;
  FavoriteRepository(this._firestore);

  Stream<List<FavoriteModel>> watchFavorites(String userId) =>
      _firestore.watchFavorites(userId);

  Future<void> add(String userId, FavoriteModel favorite, {bool isPremium = false}) async {
    final favorites = await _firestore.watchFavorites(userId).first;
    if (!isPremium && favorites.length >= AppConstants.freeFavoriteLimit) {
      throw Exception('お気に入いの上限（${AppConstants.freeFavoriteLimit}件）に達しました。プレミアムにアップグレードしてください。');
    }
    await _firestore.addFavorite(userId, favorite);
  }

  Future<void> remove(String userId, String facilityId) =>
      _firestore.removeFavorite(userId, facilityId);

  Future<void> updateStatus(String userId, String facilityId, FavoriteStatus status) =>
      _firestore.updateFavoriteStatus(userId, facilityId, status);

  Future<bool> isFavorite(String userId, String facilityId) =>
      _firestore.isFavorite(userId, facilityId);

  Future<void> updateMemo(String userId, String facilityId, String memo) =>
      _firestore.updateFavoriteMemo(userId, facilityId, memo);
}
