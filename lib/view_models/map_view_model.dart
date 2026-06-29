import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/facility_model.dart';
import '../providers/facility_provider.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class MapState {
  final List<FacilityModel> facilities;
  final Set<Marker> allMarkers;       // カテゴリ由来の全マーカー
  final LatLng cameraPosition;
  final bool isLoading;
  final String? selectedFacilityId;
  final String searchQuery;           // テキスト検索クエリ

  const MapState({
    this.facilities = const [],
    this.allMarkers = const {},
    this.cameraPosition = const LatLng(
      AppConstants.defaultLatitude,
      AppConstants.defaultLongitude,
    ),
    this.isLoading = false,
    this.selectedFacilityId,
    this.searchQuery = '',
  });

  /// 検索クエリで絞り込んだマーカーセット
  Set<Marker> get markers {
    if (searchQuery.isEmpty) return allMarkers;
    final q = searchQuery.toLowerCase();
    final matchedIds = facilities
        .where((f) =>
            f.name.toLowerCase().contains(q) ||
            f.address.toLowerCase().contains(q))
        .map((f) => f.id)
        .toSet();
    return allMarkers
        .where((m) => matchedIds.contains(m.markerId.value))
        .toSet();
  }

  /// 検索にヒットした施設リスト（クエリがある場合のみ使用）
  List<FacilityModel> get filteredFacilities {
    if (searchQuery.isEmpty) return facilities;
    final q = searchQuery.toLowerCase();
    return facilities
        .where((f) =>
            f.name.toLowerCase().contains(q) ||
            f.address.toLowerCase().contains(q))
        .toList();
  }

  MapState copyWith({
    List<FacilityModel>? facilities,
    Set<Marker>? allMarkers,
    LatLng? cameraPosition,
    bool? isLoading,
    Object? selectedFacilityId = _sentinel,
    String? searchQuery,
  }) =>
      MapState(
        facilities: facilities ?? this.facilities,
        allMarkers: allMarkers ?? this.allMarkers,
        cameraPosition: cameraPosition ?? this.cameraPosition,
        isLoading: isLoading ?? this.isLoading,
        selectedFacilityId: selectedFacilityId == _sentinel
            ? this.selectedFacilityId
            : selectedFacilityId as String?,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

const _sentinel = Object();

class MapViewModel extends StateNotifier<MapState> {
  final Ref _ref;
  MapViewModel(this._ref) : super(const MapState()) {
    _loadNearby();
  }

  Future<void> _loadNearby({String? category}) async {
    state = state.copyWith(isLoading: true);
    try {
      // デバイス位置取得 → カメラ位置を更新
      final locService = _ref.read(locationServiceProvider);
      final loc = await locService.getCurrentLocation();
      state = state.copyWith(
        cameraPosition: LatLng(loc.latitude, loc.longitude),
      );

      final facilities = await _ref.read(facilityRepositoryProvider).getNearby(
            category: category,
          );
      final markers = _buildMarkers(facilities);
      state = state.copyWith(
        facilities: facilities,
        allMarkers: markers,
        isLoading: false,
      );
    } catch (e) {
      appLogger.e('MapViewModel._loadNearby error', error: e);
      state = state.copyWith(isLoading: false);
    }
  }

  Set<Marker> _buildMarkers(List<FacilityModel> facilities) {
    return facilities
        .map(
          (f) => Marker(
            markerId: MarkerId(f.id),
            position: LatLng(f.latitude, f.longitude),
            infoWindow: InfoWindow(title: f.name, snippet: f.address),
            onTap: () => selectFacility(f.id),
          ),
        )
        .toSet();
  }

  void selectFacility(String id) {
    state = state.copyWith(selectedFacilityId: id);
  }

  void clearSelection() {
    state = state.copyWith(selectedFacilityId: null);
  }

  void filterByCategory(String? category) {
    // カテゴリ変更時は検索クエリをリセット
    state = state.copyWith(searchQuery: '');
    _loadNearby(category: category);
  }

  void setSearchQuery(String query) {
    // クエリ変更で選択中施設をクリア
    state = state.copyWith(
      searchQuery: query,
      selectedFacilityId: null,
    );
  }

  FacilityModel? get selectedFacility {
    if (state.selectedFacilityId == null) return null;
    try {
      return state.facilities.firstWhere((f) => f.id == state.selectedFacilityId);
    } catch (_) {
      return null;
    }
  }
}

// autoDispose: 地図タブを離れたら state をリセット（メモリ節約 + 再訪問で最新位置）
final mapViewModelProvider =
    StateNotifierProvider.autoDispose<MapViewModel, MapState>(MapViewModel.new);
