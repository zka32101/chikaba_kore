import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_model.dart';
import '../repositories/review_repository.dart';
import 'facility_provider.dart';

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
