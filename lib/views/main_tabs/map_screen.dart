import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/theme/app_theme.dart';
import '../../models/facility_model.dart';
import '../../utils/constants.dart';
import '../../view_models/map_view_model.dart';
import '../../views/widgets/custom_app_bar.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapViewModelProvider);
    final vm = ref.read(mapViewModelProvider.notifier);
    final selected = vm.selectedFacility;

    // 現在地が取得されたらカメラをアニメーション
    ref.listen<MapState>(mapViewModelProvider, (prev, next) {
      if (prev?.cameraPosition != next.cameraPosition && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(next.cameraPosition, AppConstants.defaultZoom),
        );
      }
    });

    return Scaffold(
      appBar: const CustomAppBar(title: '地図'),
      body: Stack(
        children: [
          // ── GoogleMap ──
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: state.cameraPosition,
              zoom: AppConstants.defaultZoom,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: state.markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            // 検索バーの高さ分だけパディング
            padding: const EdgeInsets.only(top: 56),
          ),

          // ── 検索バー（地図の上にフロート）──
          Positioned(
            top: 8,
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
