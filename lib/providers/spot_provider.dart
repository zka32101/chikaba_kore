import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase/firebase_spot_list_service.dart';
import '../firebase/firebase_spot_submission_service.dart';
import '../firebase/firebase_spot_vote_service.dart';
import '../services/spot_list_service.dart';
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
