import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase/firebase_spot_list_service.dart';
import '../firebase/firebase_spot_moderation_service.dart';
import '../firebase/firebase_spot_submission_service.dart';
import '../firebase/firebase_spot_vote_service.dart';
import '../models/pending_spot.dart';
import '../services/spot_list_service.dart';
import '../services/spot_moderation_service.dart';
import '../services/spot_submission_service.dart';
import '../services/spot_vote_service.dart';
import 'auth_provider.dart';
import 'firebase_provider.dart';
import 'safety_route_provider.dart';

/// 承認済み投稿（`shadeSpots`/`brightnessSpots`）一覧の取得。
final spotListServiceProvider = Provider<SpotListService>((ref) {
  final firebaseAvailable = ref.watch(firebaseAvailableProvider);
  if (!firebaseAvailable) return LocalSpotListService();
  return FirestoreSpotListService(FirebaseFirestore.instance);
});

/// 投稿の相互チェック（確認投票／通報）。
final spotVoteServiceProvider = Provider<SpotVoteService>((ref) {
  final firebaseAvailable = ref.watch(firebaseAvailableProvider);
  if (!firebaseAvailable) return LocalSpotVoteService();
  return FirestoreSpotVoteService(FirebaseFunctions.instance);
});

/// 投稿反映（「塗って投稿」）。
final spotSubmissionServiceProvider = Provider<SpotSubmissionService>((ref) {
  final firebaseAvailable = ref.watch(firebaseAvailableProvider);
  final repository = ref.watch(roadNetworkRepositoryProvider);
  if (!firebaseAvailable) return LocalSpotSubmissionService(repository);
  return FirestoreSpotSubmissionService(
    FirebaseFirestore.instance,
    repository,
    ref.watch(authServiceProvider),
  );
});

/// 投稿の人力承認/却下。管理者専用（Cloud Functions側でも`admin`Custom Claimを要求）。
final spotModerationServiceProvider = Provider<SpotModerationService>((ref) {
  final firebaseAvailable = ref.watch(firebaseAvailableProvider);
  if (!firebaseAvailable) return LocalSpotModerationService();
  return FirestoreSpotModerationService(FirebaseFirestore.instance, FirebaseFunctions.instance);
});

/// 承認待ち（`status == 'pending'`）の投稿一覧。管理者向け画面で使用。
final pendingSpotsProvider = FutureProvider.autoDispose<List<PendingSpot>>((ref) async {
  final service = ref.watch(spotModerationServiceProvider);
  return service.fetchPending();
});

/// 投稿の承認・却下操作。
class SpotModerationNotifier extends StateNotifier<AsyncValue<void>> {
  final SpotModerationService _service;
  final Ref _ref;
  SpotModerationNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  Future<void> approve(SpotVoteKind kind, String spotId) async {
    state = const AsyncValue.loading();
    try {
      await _service.approve(kind, spotId);
      _ref.invalidate(pendingSpotsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> reject(SpotVoteKind kind, String spotId) async {
    state = const AsyncValue.loading();
    try {
      await _service.reject(kind, spotId);
      _ref.invalidate(pendingSpotsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final spotModerationNotifierProvider =
    StateNotifierProvider<SpotModerationNotifier, AsyncValue<void>>((ref) {
  return SpotModerationNotifier(ref.watch(spotModerationServiceProvider), ref);
});
