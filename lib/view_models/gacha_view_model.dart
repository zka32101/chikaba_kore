import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../models/facility_model.dart';
import '../providers/facility_provider.dart';
import '../providers/location_provider.dart';
import '../providers/favorite_provider.dart';
import '../utils/extensions.dart';

class GachaState {
  final FacilityModel? currentGacha; // 現在のガチャ結果
  final bool isLoading;
  final String? error;
  final bool hasError; // 「候補なし」エラー

  const GachaState({
    this.currentGacha,
    this.isLoading = false,
    this.error,
    this.hasError = false,
  });

  GachaState copyWith({
    FacilityModel? currentGacha,
    bool? isLoading,
    String? error,
    bool? hasError,
  }) =>
      GachaState(
        currentGacha: currentGacha ?? this.currentGacha,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        hasError: hasError ?? this.hasError,
      );
}

class GachaViewModel extends StateNotifier<GachaState> {
  final Ref _ref;

  // ガチャパラメータ
  static const double _radiusKm = 0.8; // 800m
  static const double _minRating = 4.0; // ★4以上

  GachaViewModel(this._ref) : super(const GachaState());

  Future<void> spin() async {
    state = state.copyWith(isLoading: true, error: null, hasError: false);

    try {
      final location = _ref.read(currentLocationProvider).valueOrNull;
      if (location == null) {
        state = state.copyWith(
          isLoading: false,
          error: '位置情報を取得できません',
          hasError: true,
        );
        return;
      }

      // お気に入り（訪問済み）を取得
      final favorites = _ref.read(favoritesProvider).valueOrNull ?? [];
      final visitedFacilityIds = favorites.map((f) => f.facilityId).toSet();

      // 全施設を取得（Firestore から直接取得）
      final allFacilities = await _ref.read(facilityRepositoryProvider).getAllFacilities();

      // フィルタリング：800m以内 × 未訪問 × ★4以上
      final candidates = allFacilities.where((facility) {
        // 距離チェック
        final distKm = haversineKm(
          location.latitude,
          location.longitude,
          facility.latitude,
          facility.longitude,
        );
        if (distKm > _radiusKm) return false;

        // 訪問済みチェック
        if (visitedFacilityIds.contains(facility.id)) return false;

        // 評価チェック
        if (facility.averageRating < _minRating) return false;

        return true;
      }).toList();

      if (candidates.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'この条件の施設が見つかりません',
          hasError: true,
        );
        return;
      }

      // ランダムに1件選択
      final random = Random();
      final selected = candidates[random.nextInt(candidates.length)];

      state = state.copyWith(
        currentGacha: selected,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'ガチャに失敗しました',
        hasError: true,
      );
    }
  }

  /// ガチャ結果をリセット
  void reset() {
    state = const GachaState();
  }
}

final gachaViewModelProvider =
    StateNotifierProvider<GachaViewModel, GachaState>(GachaViewModel.new);
