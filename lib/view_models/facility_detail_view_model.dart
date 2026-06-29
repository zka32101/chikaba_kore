import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/facility_model.dart';
import '../models/review_model.dart';
import '../providers/facility_provider.dart';
import '../repositories/review_repository.dart';

const _reviewPageSize = 5;   // 初期表示件数
const _reviewFetchLimit = 50; // Firestore から一括取得する上限

class FacilityDetailState {
  final FacilityModel? facility;
  final List<ReviewModel> reviews;       // 取得済み全件
  final int reviewDisplayCount;          // 現在表示している件数
  final bool isLoading;
  final bool isLoadingReviews;
  final String? error;
  /// ソート順: 'new'（新着）、'rating_high'（高評価）、'rating_low'（低評価）
  final String reviewSortBy;
  /// フィルタリング: 最小評価。null で全件表示
  final double? reviewMinRating;

  const FacilityDetailState({
    this.facility,
    this.reviews = const [],
    this.reviewDisplayCount = _reviewPageSize,
    this.isLoading = true,
    this.isLoadingReviews = false,
    this.error,
    this.reviewSortBy = 'new',
    this.reviewMinRating,
  });

  /// フィルタリング＆ソート済みレビュー
  List<ReviewModel> get filteredAndSortedReviews {
    var result = reviews;
    // フィルタリング
    if (reviewMinRating != null) {
      result = result.where((r) => r.rating >= reviewMinRating!).toList();
    }
    // ソート
    switch (reviewSortBy) {
      case 'rating_high':
        result.sort((a, b) => b.rating.compareTo(a.rating));
      case 'rating_low':
        result.sort((a, b) => a.rating.compareTo(b.rating));
      case 'new':
      default:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return result;
  }

  /// 現在表示するレビューのサブリスト
  List<ReviewModel> get visibleReviews =>
      filteredAndSortedReviews.take(reviewDisplayCount).toList();

  /// まだ表示していないレビューがあるか
  bool get hasMoreReviews => reviewDisplayCount < filteredAndSortedReviews.length;

  /// フィルタリング後の全件数
  int get filteredReviewCount => filteredAndSortedReviews.length;

  FacilityDetailState copyWith({
    FacilityModel? facility,
    List<ReviewModel>? reviews,
    int? reviewDisplayCount,
    bool? isLoading,
    bool? isLoadingReviews,
    String? error,
    String? reviewSortBy,
    double? Function()? reviewMinRating,
  }) =>
      FacilityDetailState(
        facility: facility ?? this.facility,
        reviews: reviews ?? this.reviews,
        reviewDisplayCount: reviewDisplayCount ?? this.reviewDisplayCount,
        isLoading: isLoading ?? this.isLoading,
        isLoadingReviews: isLoadingReviews ?? this.isLoadingReviews,
        error: error,
        reviewSortBy: reviewSortBy ?? this.reviewSortBy,
        reviewMinRating: reviewMinRating != null ? reviewMinRating() : this.reviewMinRating,
      );
}

class FacilityDetailViewModel extends StateNotifier<FacilityDetailState> {
  final Ref _ref;
  final String facilityId;

  FacilityDetailViewModel(this._ref, this.facilityId)
      : super(const FacilityDetailState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final facility =
          await _ref.read(facilityRepositoryProvider).getById(facilityId);
      state = state.copyWith(facility: facility, isLoading: false);
      if (facility != null) await _loadReviews();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 外部からリトライ（エラー時・引っ張って更新など）
  Future<void> refresh() => _load();

  Future<void> _loadReviews() async {
    state = state.copyWith(isLoadingReviews: true);
    final repo = ReviewRepository(_ref.read(firestoreServiceProvider));
    final reviews =
        await repo.getReviews(facilityId, limit: _reviewFetchLimit);
    state = state.copyWith(
      reviews: reviews,
      reviewDisplayCount: _reviewPageSize,
      isLoadingReviews: false,
    );
  }

  /// クチコミ投稿後などに外部から呼ぶリフレッシュ
  Future<void> refreshReviews() => _loadReviews();

  /// 「もっと読む」: 表示件数を _reviewPageSize ずつ増やす
  void loadMoreReviews() {
    if (!state.hasMoreReviews) return;
    state = state.copyWith(
      reviewDisplayCount: state.reviewDisplayCount + _reviewPageSize,
    );
  }

  /// レビューのソート順を変更
  void setSortBy(String sortBy) {
    state = state.copyWith(
      reviewSortBy: sortBy,
      reviewDisplayCount: _reviewPageSize, // リセット
    );
  }

  /// レビューの最小評価フィルターを設定
  void setMinRating(double? minRating) {
    state = state.copyWith(
      reviewMinRating: () => minRating,
      reviewDisplayCount: _reviewPageSize, // リセット
    );
  }
}

// autoDispose: 画面を離れたら state をリセット（再訪問で最新データを取得）
final facilityDetailViewModelProvider =
    StateNotifierProvider.autoDispose
        .family<FacilityDetailViewModel, FacilityDetailState, String>(
  (ref, facilityId) => FacilityDetailViewModel(ref, facilityId),
);
