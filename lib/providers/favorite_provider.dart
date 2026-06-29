import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/facility_model.dart';
import '../models/favorite_model.dart';
import '../repositories/favorite_repository.dart';
import 'auth_provider.dart';
import 'facility_provider.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>(
  (ref) => FavoriteRepository(ref.watch(firestoreServiceProvider)),
);

final favoritesProvider = StreamProvider<List<FavoriteModel>>((ref) {
  final userAsync = ref.watch(authNotifierProvider);
  final uid = userAsync.valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(favoriteRepositoryProvider).watchFavorites(uid);
});

final wantToGoProvider = Provider<List<FavoriteModel>>((ref) {
  final favorites = ref.watch(favoritesProvider).valueOrNull ?? [];
  return favorites.where((f) => f.status == FavoriteStatus.wantToGo).toList();
});

final willGoProvider = Provider<List<FavoriteModel>>((ref) {
  final favorites = ref.watch(favoritesProvider).valueOrNull ?? [];
  return favorites.where((f) => f.status == FavoriteStatus.willGo).toList();
});

class FavoriteNotifier extends StateNotifier<AsyncValue<void>> {
  final FavoriteRepository _repo;
  final String _userId;
  final bool _isPremium;

  FavoriteNotifier(this._repo, this._userId, this._isPremium)
      : super(const AsyncValue.data(null));

  Future<void> toggle(FacilityModel facility) async {
    final isFav = await _repo.isFavorite(_userId, facility.id);
    if (isFav) {
      await _repo.remove(_userId, facility.id);
    } else {
      final favorite = FavoriteModel(
        id: facility.id,
        facilityId: facility.id,
        facilityName: facility.name,
        facilityThumbnailUrl: facility.thumbnailUrl,
        facilityCategory: facility.category,
        status: FavoriteStatus.wantToGo,
        savedAt: DateTime.now(),
      );
      await _repo.add(_userId, favorite, isPremium: _isPremium);
    }
  }

  Future<void> updateStatus(String facilityId, FavoriteStatus status) async {
    await _repo.updateStatus(_userId, facilityId, status);
  }

  Future<void> remove(String facilityId) async {
    await _repo.remove(_userId, facilityId);
  }

  Future<void> updateMemo(String facilityId, String memo) async {
    await _repo.updateMemo(_userId, facilityId, memo);
  }
}

final favoriteNotifierProvider =
    StateNotifierProvider<FavoriteNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(favoriteRepositoryProvider);
  final user = ref.watch(authNotifierProvider).valueOrNull;
  return FavoriteNotifier(repo, user?.uid ?? '', user?.isPremium ?? false);
});
