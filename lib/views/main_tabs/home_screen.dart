import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../view_models/home_view_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ui_provider.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/gacha_widget.dart';
import 'home_reel_tab.dart';
import 'home_grid_tab.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final vm = ref.read(homeViewModelProvider.notifier);
    final selectedCity =
        ref.watch(authNotifierProvider).valueOrNull?.selectedCity;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        showLogo: true,
        subtitleWidget: _buildCityToggle(state, selectedCity, vm),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
            onPressed: () => context.push('/search'),
            tooltip: '検索',
          ),
          IconButton(
            icon: Icon(
              state.viewMode == FeedViewMode.reel
                  ? Icons.grid_view_rounded
                  : Icons.view_stream_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: vm.toggleViewMode,
          ),
          IconButton(
            icon: Icon(
              state.isOpenNowFilter ? Icons.access_time_filled : Icons.access_time_outlined,
              color: state.isOpenNowFilter ? AppColors.primary : AppColors.textSecondary,
            ),
            onPressed: vm.toggleOpenNowFilter,
            tooltip: '営業中のみ',
          ),
        ],
      ),
      body: Column(
        children: [
          _CategoryBar(
            selected: state.selectedCategory,
            onSelect: vm.selectCategory,
          ),
          const _GachaButton(),
          _RatingFilterBar(
            minRating: state.minRating,
            onSelect: vm.setMinRating,
          ),
          Expanded(
            child: state.isLoading
                ? const LoadingShimmer()
                : state.error != null
                    ? _ErrorView(error: state.error!, onRetry: vm.refresh)
                    : state.filteredFacilities.isEmpty
                        ? const _EmptyView()
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: vm.refresh,
                            child: state.viewMode == FeedViewMode.reel
                                ? HomeReelTab(facilities: state.filteredFacilities)
                                : HomeGridTab(facilities: state.filteredFacilities),
                          ),
          ),
        ],
      ),
    );
  }

  Widget? _buildCityToggle(
    HomeState state,
    String? selectedCity,
    HomeViewModel vm,
  ) {
    if (state.showAllCities) {
      return GestureDetector(
        onTap: vm.toggleShowAllCities,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🌍', style: TextStyle(fontSize: 12)),
              SizedBox(width: 4),
              Text(
                '全エリア',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 2),
              Icon(Icons.expand_more, size: 14, color: AppColors.primary),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: vm.toggleShowAllCities,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 3),
            Text(
              selectedCity ?? '場所未設定',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _CategoryBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final allCategories = ['all', ...AppConstants.facilityCategories];

    return Container(
      height: 56,
      color: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: allCategories.length,
        itemBuilder: (_, i) {
          final cat = allCategories[i];
          final isAll = cat == 'all';
          final isSelected = isAll ? selected == 'all' : cat == selected;

          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAll
                        ? Icons.apps_rounded
                        : (AppConstants.categoryIcons[cat] ?? Icons.store),
                    size: 14,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isAll ? 'すべて' : (AppConstants.categoryNames[cat] ?? cat),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RatingFilterBar extends StatelessWidget {
  final double? minRating;
  final void Function(double?) onSelect;
  const _RatingFilterBar({required this.minRating, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const ratings = [3.0, 4.0, 4.5];
    const labels = ['3★以上', '4★以上', '4.5★以上'];

    return Container(
      height: 40,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ratings.length,
        itemBuilder: (_, i) {
          final isSelected = minRating == ratings[i];
          return GestureDetector(
            onTap: () => onSelect(isSelected ? null : ratings[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.rating.withValues(alpha: 0.15)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.rating : AppColors.divider,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: isSelected ? AppColors.rating : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.rating : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.divider,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              '読み込みに失敗しました',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('再試行'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(160, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.divider,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_outlined, size: 40, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              '該当する施設が見つかりません',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'フィルターを変えて\nもう一度お試しください',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// ガチャボタン（ホーム画面専用）
class _GachaButton extends StatelessWidget {
  const _GachaButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useRootNavigator: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => GachaResultSheet(
              onClose: () => ctx.pop(),
            ),
          );
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('✨', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text('🎰', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text(
                '今日どこ行く？ガチャを引く',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(width: 8),
              Text('✨', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
