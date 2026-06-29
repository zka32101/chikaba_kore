import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/facility_model.dart';
import '../providers/facility_provider.dart';
import '../providers/ui_provider.dart';
import '../utils/constants.dart';

class HomeState {
  final List<FacilityModel> facilities;
  final bool isLoading;
  final bool isLoadingMore;   // 追加読み込み中
  final bool hasMore;         // まだ続きがあるか
  final String? error;
  final String selectedCategory;
  final FeedViewMode viewMode;
  final bool isOpenNowFilter;
  final double? minRating;    // 評価フィルター
  /// すべての都市を表示。false の場合はユーザーの selectedCity のみ
  final bool showAllCities;

  const HomeState({
    this.facilities = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.selectedCategory = 'dining',
    this.viewMode = FeedViewMode.reel,
    this.isOpenNowFilter = false,
    this.minRating,
    this.showAllCities = false,
  });

  HomeState copyWith({
    List<FacilityModel>? facilities,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? selectedCategory,
    FeedViewMode? viewMode,
    bool? isOpenNowFilter,
    Object? minRating = _sentinel,
    bool? showAllCities,
  }) =>
      HomeState(
        facilities: facilities ?? this.facilities,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: error,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        viewMode: viewMode ?? this.viewMode,
        isOpenNowFilter: isOpenNowFilter ?? this.isOpenNowFilter,
        minRating: minRating == _sentinel ? this.minRating : minRating as double?,
        showAllCities: showAllCities ?? this.showAllCities,
      );

  List<FacilityModel> get filteredFacilities {
    var list = facilities;
    if (isOpenNowFilter) list = list.where((f) => f.isOpenNow).toList();
    if (minRating != null) list = list.where((f) => f.averageRating >= minRating!).toList();
    return list;
  }
}

const _sentinel = Object();

const _pageSize = 20;

class HomeViewModel extends StateNotifier<HomeState> {
  final Ref _ref;
  HomeViewModel(this._ref) : super(const HomeState()) {
    _loadFeed('dining');
  }

  Future<void> _loadFeed(String category) async {
    state = state.copyWith(isLoading: true, error: null, hasMore: true, facilities: []);
    try {
      final facilities = await _ref
          .read(facilityRepositoryProvider)
          .getFeedByCategory(category, limit: _pageSize);
      state = state.copyWith(
        facilities: facilities,
        isLoading: false,
        hasMore: facilities.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: AppConstants.networkError);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final more = await _ref
          .read(facilityRepositoryProvider)
          .getFeedByCategory(state.selectedCategory, limit: _pageSize, offset: state.facilities.length);
      state = state.copyWith(
        facilities: [...state.facilities, ...more],
        isLoadingMore: false,
        hasMore: more.length == _pageSize,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    _loadFeed(category);
  }

  void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == FeedViewMode.reel ? FeedViewMode.grid : FeedViewMode.reel,
    );
  }

  void toggleOpenNowFilter() {
    state = state.copyWith(isOpenNowFilter: !state.isOpenNowFilter);
  }

  void setMinRating(double? rating) {
    // 同値タップでリセット（トグル）
    final next = state.minRating == rating ? null : rating;
    state = state.copyWith(minRating: next);
  }

  /// すべての都市を表示するか、選択中の都市のみにするかをトグル
  void toggleShowAllCities() {
    state = state.copyWith(showAllCities: !state.showAllCities);
  }

  Future<void> refresh() => _loadFeed(state.selectedCategory);
}

final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);
