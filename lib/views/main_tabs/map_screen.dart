import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/theme/app_theme.dart';
import '../../models/facility_model.dart';
import '../../models/road_segment.dart';
import '../../models/route_result.dart';
import '../../providers/safety_route_provider.dart';
import '../../providers/ui_provider.dart';
import '../../utils/constants.dart';
import '../../utils/maps_launcher.dart';
import '../../view_models/map_view_model.dart';
import '../../views/widgets/custom_app_bar.dart';
import '../../views/widgets/map/comfort_score_color.dart';
import '../../views/widgets/map/map_base_options.dart';
import '../../views/widgets/map/map_camera_controller.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _cameraController = MapCameraController();
  final _searchController = TextEditingController();

  // モードスイッチャー＋検索バーの高さ分だけパディングした、施設探索モードの基本オプション。
  static final _facilityMapOptions = const MapBaseOptions().copyWith(
    padding: const EdgeInsets.only(top: 104),
  );

  // モードスイッチャーの高さ分だけパディングした、安全ルートモードの基本オプション。
  static final _safetyRouteMapOptions = const MapBaseOptions().copyWith(
    padding: const EdgeInsets.only(top: 56),
  );

  @override
  void dispose() {
    _cameraController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(mapModeProvider);

    // 施設探索モード: 現在地が取得されたらカメラをアニメーション
    ref.listen<MapState>(mapViewModelProvider, (prev, next) {
      if (ref.read(mapModeProvider) != MapMode.facility) return;
      if (prev?.cameraPosition != next.cameraPosition) {
        _cameraController.animateToPosition(next.cameraPosition, zoom: AppConstants.defaultZoom);
      }
    });

    // 安全ルートモード: ルートが取得されたらルート全体が収まるようカメラをアニメーション
    ref.listen<AsyncValue<RouteResult?>>(safetyRouteProvider, (prev, next) {
      if (ref.read(mapModeProvider) != MapMode.safetyRoute) return;
      final route = next.valueOrNull;
      if (route == null || route.nodes.isEmpty) return;
      _cameraController.animateToBounds(_boundsForNodes(route.nodes));
    });

    return Scaffold(
      appBar: const CustomAppBar(title: '地図'),
      body: Stack(
        children: [
          if (mode == MapMode.facility) _buildFacilityMode(context) else _buildSafetyRouteMode(context),

          // ── モードスイッチャー（常時最上部にフロート）──
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: _ModeSwitcher(
              mode: mode,
              onChanged: (m) => ref.read(mapModeProvider.notifier).state = m,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityMode(BuildContext context) {
    final state = ref.watch(mapViewModelProvider);
    final vm = ref.read(mapViewModelProvider.notifier);
    final selected = vm.selectedFacility;
    final options = _facilityMapOptions;

    return Stack(
      children: [
        // ── GoogleMap ──
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: state.cameraPosition,
            zoom: AppConstants.defaultZoom,
          ),
          onMapCreated: _cameraController.attach,
          markers: state.markers,
          mapType: options.mapType,
          myLocationEnabled: options.myLocationEnabled,
          myLocationButtonEnabled: options.myLocationButtonEnabled,
          zoomControlsEnabled: options.zoomControlsEnabled,
          zoomGesturesEnabled: options.zoomGesturesEnabled,
          scrollGesturesEnabled: options.scrollGesturesEnabled,
          mapToolbarEnabled: options.mapToolbarEnabled,
          padding: options.padding,
        ),

        // ── 検索バー（モードスイッチャーの下にフロート）──
        Positioned(
          top: 56,
          left: 12,
          right: 12,
          child: _MapSearchBar(
            controller: _searchController,
            onChanged: vm.setSearchQuery,
            onClear: () {
              _searchController.clear();
              vm.setSearchQuery('');
            },
            resultCount: state.searchQuery.isEmpty
                ? null
                : state.filteredFacilities.length,
          ),
        ),

        if (state.isLoading)
          const Center(child: CircularProgressIndicator()),

        Positioned(
          bottom: selected != null ? 180 : 16,
          left: 0,
          right: 0,
          child: _CategoryFilterBar(onSelect: vm.filterByCategory),
        ),

        if (selected != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _FacilityBottomSheet(
              facility: selected,
              onClose: vm.clearSelection,
              onTap: () => context.push('/facility/${selected.id}'),
            ),
          ),
      ],
    );
  }

  Widget _buildSafetyRouteMode(BuildContext context) {
    final routeAsync = ref.watch(safetyRouteProvider);
    final route = routeAsync.valueOrNull;
    final options = _safetyRouteMapOptions;

    return Stack(
      children: [
        // ── GoogleMap ──
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
            zoom: AppConstants.defaultZoom,
          ),
          onMapCreated: _cameraController.attach,
          polylines: route != null ? _polylinesForRoute(route) : const {},
          mapType: options.mapType,
          myLocationEnabled: options.myLocationEnabled,
          myLocationButtonEnabled: options.myLocationButtonEnabled,
          zoomControlsEnabled: options.zoomControlsEnabled,
          zoomGesturesEnabled: options.zoomGesturesEnabled,
          scrollGesturesEnabled: options.scrollGesturesEnabled,
          mapToolbarEnabled: options.mapToolbarEnabled,
          padding: options.padding,
        ),

        if (routeAsync.isLoading)
          const Center(child: CircularProgressIndicator()),

        if (routeAsync.hasError)
          Center(
            child: _SafetyRouteErrorCard(
              onRetry: () => ref.invalidate(safetyRouteProvider),
            ),
          )
        else if (route != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _SafetyRouteInfoCard(route: route),
          )
        else if (!routeAsync.isLoading)
          const Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _SafetyRouteEmptyCard(),
          ),
      ],
    );
  }

  Set<Polyline> _polylinesForRoute(RouteResult route) {
    return route.segments.map((segment) {
      return Polyline(
        polylineId: PolylineId(segment.id),
        points: [
          LatLng(segment.from.lat, segment.from.lon),
          LatLng(segment.to.lat, segment.to.lon),
        ],
        color: comfortScoreColor(segment.comfortScore),
        width: 5,
      );
    }).toSet();
  }

  LatLngBounds _boundsForNodes(List<RoadNode> nodes) {
    var minLat = nodes.first.lat;
    var maxLat = nodes.first.lat;
    var minLon = nodes.first.lon;
    var maxLon = nodes.first.lon;
    for (final node in nodes) {
      minLat = math.min(minLat, node.lat);
      maxLat = math.max(maxLat, node.lat);
      minLon = math.min(minLon, node.lon);
      maxLon = math.max(maxLon, node.lon);
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  final MapMode mode;
  final ValueChanged<MapMode> onChanged;

  const _ModeSwitcher({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SegmentedButton<MapMode>(
          segments: const [
            ButtonSegment(
              value: MapMode.facility,
              label: Text('お店を探す'),
              icon: Icon(Icons.storefront_outlined, size: 16),
            ),
            ButtonSegment(
              value: MapMode.safetyRoute,
              label: Text('安全ルートを探す'),
              icon: Icon(Icons.shield_outlined, size: 16),
            ),
          ],
          selected: {mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ),
    );
  }
}

class _SafetyRouteInfoCard extends StatelessWidget {
  final RouteResult route;

  const _SafetyRouteInfoCard({required this.route});

  @override
  Widget build(BuildContext context) {
    final distanceLabel = route.distanceM >= 1000
        ? '${(route.distanceM / 1000).toStringAsFixed(1)}km'
        : '${route.distanceM.toStringAsFixed(0)}m';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.route_outlined, color: comfortScoreColor(route.averageComfortScore)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('近くの安心ルート', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '距離 $distanceLabel・安心スコア ${(route.averageComfortScore * 100).round()}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (route.isFromCache) ...[
                  const SizedBox(height: 4),
                  Text(
                    'オフラインキャッシュを表示中（実際の状況と異なる場合があります）',
                    style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyRouteEmptyCard extends StatelessWidget {
  const _SafetyRouteEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Text('近くに安心ルートが見つかりませんでした'),
    );
  }
}

class _SafetyRouteErrorCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _SafetyRouteErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('安心ルートの検索に失敗しました'),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('再試行')),
        ],
      ),
    );
  }
}

class _MapSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onClear;
  final int? resultCount; // null = 非表示

  const _MapSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.resultCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14, right: 8),
            child: Icon(Icons.search, size: 18, color: AppColors.textSecondary),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '施設名・エリアで絞り込む',
                hintStyle: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                // ヒット件数バッジ
                suffix: resultCount != null
                    ? Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$resultCount件',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          // クリアボタン（入力時のみ表示）
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) => value.text.isNotEmpty
                ? GestureDetector(
                    onTap: onClear,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.close,
                          size: 18, color: AppColors.textSecondary),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterBar extends StatefulWidget {
  final void Function(String?) onSelect;
  const _CategoryFilterBar({required this.onSelect});

  @override
  State<_CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<_CategoryFilterBar> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: AppConstants.facilityCategories.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return _FilterChip(
              label: 'すべて',
              isSelected: _selected == null,
              onTap: () {
                setState(() => _selected = null);
                widget.onSelect(null);
              },
            );
          }
          final cat = AppConstants.facilityCategories[i - 1];
          return _FilterChip(
            label: AppConstants.categoryNames[cat]!,
            isSelected: _selected == cat,
            onTap: () {
              setState(() => _selected = cat);
              widget.onSelect(cat);
            },
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _FacilityBottomSheet extends StatelessWidget {
  final FacilityModel facility;
  final VoidCallback onClose;
  final VoidCallback onTap;

  const _FacilityBottomSheet({
    required this.facility,
    required this.onClose,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(facility.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(facility.address,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: onClose),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, color: AppColors.rating, size: 16),
              const SizedBox(width: 4),
              Text(facility.averageRating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text('(${facility.reviewCount}件)',
                  style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.directions_rounded,
                    color: Color(0xFF00B377)),
                tooltip: '経路を見る',
                onPressed: () => MapsLauncher.openDirections(
                    facility.latitude, facility.longitude),
              ),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 40),
                ),
                child: const Text('詳細を見る'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
