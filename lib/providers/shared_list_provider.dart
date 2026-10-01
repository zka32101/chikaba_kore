import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase/firebase_shared_list_service.dart';
import '../models/favorite_model.dart';
import '../models/shared_list.dart';
import '../services/shared_list_service.dart';
import 'firebase_provider.dart';

/// お気に入りリストの共有（作成・取得）。
final sharedListServiceProvider = Provider<SharedListService>((ref) {
  final firebaseAvailable = ref.watch(firebaseAvailableProvider);
  if (!firebaseAvailable) return LocalSharedListService();
  return FirestoreSharedListService(FirebaseFirestore.instance);
});

/// 指定した共有コードのリスト。
final sharedListProvider =
    FutureProvider.autoDispose.family<SharedList?, String>((ref, shareCode) async {
  final service = ref.watch(sharedListServiceProvider);
  return service.fetchSharedList(shareCode);
});

/// 共有リストの作成操作。
class SharedListCreateNotifier extends StateNotifier<AsyncValue<String?>> {
  final SharedListService _service;
  SharedListCreateNotifier(this._service) : super(const AsyncValue.data(null));

  Future<String> create(String ownerNickname, List<FavoriteModel> favorites) async {
    state = const AsyncValue.loading();
    try {
      final shareCode = await _service.createSharedList(ownerNickname, favorites);
      state = AsyncValue.data(shareCode);
      return shareCode;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final sharedListCreateNotifierProvider =
    StateNotifierProvider<SharedListCreateNotifier, AsyncValue<String?>>((ref) {
  return SharedListCreateNotifier(ref.watch(sharedListServiceProvider));
});
