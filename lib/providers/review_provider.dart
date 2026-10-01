import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/review_model.dart';
import '../repositories/review_repository.dart';
import 'facility_provider.dart';

const _kHelpfulVotedReviewIdsKey = 'helpful_voted_review_ids';

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewRepository(ref.watch(firestoreServiceProvider)),
);

/// クチコミの通報操作。
class ReviewReportNotifier extends StateNotifier<AsyncValue<void>> {
  final ReviewRepository _repo;
  ReviewReportNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> report(String reviewId, String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.reportReview(reviewId, userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final reviewReportNotifierProvider =
    StateNotifierProvider<ReviewReportNotifier, AsyncValue<void>>((ref) {
  return ReviewReportNotifier(ref.watch(reviewRepositoryProvider));
});

/// 承認待ち（status == 'pending'）のクチコミ一覧。管理者向け画面で使用。
final pendingReviewsProvider =
    FutureProvider.autoDispose<List<ReviewModel>>((ref) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getPendingReviews();
});

/// クチコミの承認・却下操作。管理者専用（firestore.rulesでも isAdmin() を要求）。
class ReviewModerationNotifier extends StateNotifier<AsyncValue<void>> {
  final ReviewRepository _repo;
  final Ref _ref;
  ReviewModerationNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> approve(String reviewId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.approveReview(reviewId);
      _ref.invalidate(pendingReviewsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> reject(String reviewId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.rejectReview(reviewId);
      _ref.invalidate(pendingReviewsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final reviewModerationNotifierProvider =
    StateNotifierProvider<ReviewModerationNotifier, AsyncValue<void>>((ref) {
  return ReviewModerationNotifier(ref.watch(reviewRepositoryProvider), ref);
});

/// 「参考になった」の投票操作。サーバー側（firestore.rules）が同一ユーザーの
/// 二重投票を拒否するが、UI側で投票済みかどうかを即座に表示するためローカル
/// （Hive）にも投票済みのreviewIdを記録する。
class ReviewHelpfulNotifier extends StateNotifier<AsyncValue<void>> {
  final ReviewRepository _repo;
  ReviewHelpfulNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> vote(String reviewId, String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.voteHelpful(reviewId, userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final reviewHelpfulNotifierProvider =
    StateNotifierProvider<ReviewHelpfulNotifier, AsyncValue<void>>((ref) {
  return ReviewHelpfulNotifier(ref.watch(reviewRepositoryProvider));
});

/// 「参考になった」を投票済みのreviewId一覧（このデバイス内のみ、Hiveで永続化）。
class HelpfulVoteCacheNotifier extends StateNotifier<Set<String>> {
  HelpfulVoteCacheNotifier() : super(_loadFromHive());

  static Set<String> _loadFromHive() {
    final box = Hive.box('user');
    final stored = box.get(_kHelpfulVotedReviewIdsKey, defaultValue: const <String>[]) as List;
    return stored.cast<String>().toSet();
  }

  Future<void> markVoted(String reviewId) async {
    if (state.contains(reviewId)) return;
    final updated = {...state, reviewId};
    await Hive.box('user').put(_kHelpfulVotedReviewIdsKey, updated.toList());
    state = updated;
  }
}

final helpfulVoteCacheProvider =
    StateNotifierProvider<HelpfulVoteCacheNotifier, Set<String>>(
  (ref) => HelpfulVoteCacheNotifier(),
);
