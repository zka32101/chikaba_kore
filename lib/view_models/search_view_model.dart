import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/facility_model.dart';
import '../providers/facility_provider.dart';
import '../services/cache_service.dart';
import '../utils/constants.dart';

class SearchState {
  final String query;
  final String? selectedCategory;
  final bool isOpenNowFilter;
  final double? minRating; // null = すべて、3.0、4.0 など
  final List<FacilityModel> results;
  final List<String> recentSearches;
  final bool isLoading;
  final String? error;
  final bool hasSearched;
  /// ソート順: 'default'（検索スコア順）、'distance'（距離順）、'rating'（評価順）、'new'（新着順）
  final String sortBy;

  const SearchState({
    this.query = '',
    this.selectedCategory,
    this.isOpenNowFilter = false,
    this.minRating,
    this.results = const [],
    this.recentSearches = const [],
    this.isLoading = false,
    this.error,
    this.hasSearched = false,
    this.sortBy = 'default',
  });

  SearchState copyWith({
    String? query,
    Object? selectedCategory = _sentinel,
    bool? isOpenNowFilter,
    Object? minRating = _sentinel,
    List<FacilityModel>? results,
    List<String>? recentSearches,
    bool? isLoading,
    Object? error = _sentinel,
    bool? hasSearched,
    String? sortBy,
  }) =>
      SearchState(
        query: query ?? this.query,
        selectedCategory: selectedCategory == _sentinel
            ? this.selectedCategory
            : selectedCategory as String?,
        isOpenNowFilter: isOpenNowFilter ?? this.isOpenNowFilter,
        minRating: minRating == _sentinel ? this.minRating : minRating as double?,
        results: results ?? this.results,
        recentSearches: recentSearches ?? this.recentSearches,
        isLoading: isLoading ?? this.isLoading,
        error: error == _sentinel ? this.error : error as String?,
        hasSearched: hasSearched ?? this.hasSearched,
        sortBy: sortBy ?? this.sortBy,
      );
}

const _sentinel = Object();

class SearchViewModel extends StateNotifier<SearchState> {
  final Ref _ref;
  final _cache = CacheService();
  Timer? _debounce;

  SearchViewModel(this._ref) : super(const SearchState()) {
    _loadHistory();
  }

  void _loadHistory() {
    final history = _cache.searchHistory;
    state = state.copyWith(recentSearches: history);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void onQueryChanged(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    if (query.isEmpty && state.selectedCategory == null) {
      state = state.copyWith(results: [], hasSearched: false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  /// 履歴タップ時など、クエリをセットして即検索
  void searchByQuery(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    _search();
  }

  void selectCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
    _search();
  }

  void toggleOpenNow() {
    state = state.copyWith(isOpenNowFilter: !state.isOpenNowFilter);
    if (state.hasSearched) _search();
  }

  void setMinRating(double? rating) {
    // 同じ値をタップしたらリセット（トグル）
    final next = state.minRating == rating ? null : rating;
    state = state.copyWith(minRating: next);
    if (state.hasSearched) _search();
  }

  Future<void> clearHistory() async {
    await _cache.clearSearchHistory();
    state = state.copyWith(recentSearches: []);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
    _sortResults();
  }

  /// ソート処理（location パラメータは別途注入する必要があるため、ここでは実装不可）
  void _sortResults() {
    final results = state.results;
    final sorted = List<FacilityModel>.from(results);

    switch (state.sortBy) {
      case 'rating':
        sorted.sort((a, b) => b.averageRating.compareTo(a.averageRating));
      case 'new':
        // 新着順（createdAt でソート）
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'distance':
        // 距離順は location が必要なため、UI 層で処理すべき
        // ここでは 'default' のまま
        break;
      case 'default':
      default:
        // デフォルトは検索スコア順（そのまま）
        break;
    }

    state = state.copyWith(results: sorted);
  }

  Future<void> _search() async {
    if (state.query.isEmpty && state.selectedCategory == null) return;
    state = state.copyWith(isLoading: true, error: null);
    // キーワードがあれば履歴に保存
    if (state.query.trim().isNotEmpty) {
      await _cache.addSearchHistory(state.query.trim());
      state = state.copyWith(recentSearches: _cache.searchHistory);
    }
    try {
      var results = await _ref.read(facilityRepositoryProvider).search(
            query: state.query,
            category: state.selectedCategory,
            openNowOnly: state.isOpenNowFilter,
          );
      // 評価フィルター（クライアントサイド）
      if (state.minRating != null) {
        results = results
            .where((f) => f.averageRating >= state.minRating!)
            .toList();
      }
      state = state.copyWith(results: results, isLoading: false, hasSearched: true);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: AppConstants.networkError,
        hasSearched: true,
      );
    }
  }
}

final searchViewModelProvider =
    StateNotifierProvider.autoDispose<SearchViewModel, SearchState>(SearchViewModel.new);
