import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/facility_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../repositories/facility_repository.dart';

const _kHiddenGemVotedFacilityIdsKey = 'hidden_gem_voted_facility_ids';

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

final facilityRepositoryProvider = Provider<FacilityRepository>(
  (ref) => FacilityRepository(
    ref.watch(firestoreServiceProvider),
    ref.watch(locationServiceProvider),
  ),
);

final selectedCategoryProvider = StateProvider<String>((ref) => 'dining');

final facilityFeedProvider =
    FutureProvider.family<List<FacilityModel>, String>((ref, category) async {
  final repo = ref.watch(facilityRepositoryProvider);
  return repo.getFeedByCategory(category);
});

final nearbyFacilitiesProvider = FutureProvider<List<FacilityModel>>((ref) async {
  final repo = ref.watch(facilityRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  return repo.getNearby(category: category);
});

final facilityDetailProvider =
    FutureProvider.family<FacilityModel?, String>((ref, id) async {
  final repo = ref.watch(facilityRepositoryProvider);
  return repo.getById(id);
});

/// 「穴場だと思う」の投票操作。サーバー側（firestore.rules）が同一ユーザーの
/// 二重投票を拒否するが、UI側で投票済みかどうかを即座に表示するためローカル
/// （Hive）にも投票済みのfacilityIdを記録する
/// （`reviewHelpfulNotifierProvider`/`helpfulVoteCacheProvider`と同じ考え方）。
/// カウント（`hiddenGemVoteCount`）自体は`FacilityDetailViewModel`が保持する
/// `state.facility`の再取得（`refresh()`）で反映するため、呼び出し側が必要に
/// 応じて行う。
class HiddenGemVoteNotifier extends StateNotifier<AsyncValue<void>> {
  final FacilityRepository _repo;
  HiddenGemVoteNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> vote(String facilityId, String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.voteHiddenGem(facilityId, userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final hiddenGemVoteNotifierProvider =
    StateNotifierProvider<HiddenGemVoteNotifier, AsyncValue<void>>((ref) {
  return HiddenGemVoteNotifier(ref.watch(facilityRepositoryProvider));
});

/// 「穴場だと思う」を投票済みのfacilityId一覧（このデバイス内のみ、Hiveで永続化）。
class HiddenGemVoteCacheNotifier extends StateNotifier<Set<String>> {
  HiddenGemVoteCacheNotifier() : super(_loadFromHive());

  static Set<String> _loadFromHive() {
    final box = Hive.box('user');
    final stored =
        box.get(_kHiddenGemVotedFacilityIdsKey, defaultValue: const <String>[]) as List;
    return stored.cast<String>().toSet();
  }

  Future<void> markVoted(String facilityId) async {
    if (state.contains(facilityId)) return;
    final updated = {...state, facilityId};
    await Hive.box('user').put(_kHiddenGemVotedFacilityIdsKey, updated.toList());
    state = updated;
  }
}

final hiddenGemVoteCacheProvider =
    StateNotifierProvider<HiddenGemVoteCacheNotifier, Set<String>>(
  (ref) => HiddenGemVoteCacheNotifier(),
);
