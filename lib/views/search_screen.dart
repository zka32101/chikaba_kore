import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import '../providers/favorite_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../view_models/search_view_model.dart';
import 'widgets/facility_card.dart';
import 'widgets/loading_shimmer.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchViewModelProvider);
    final vm = ref.read(searchViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '施設名・エリアで検索',
              border: InputBorder.none,
              hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              isCollapsed: true,
            ),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            textAlignVertical: TextAlignVertical.center,
            onChanged: vm.onQueryChanged,
          ),
        ),
        actions: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, child) => value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel_rounded, color: AppColors.textSecondary),
                    onPressed: () {
                      _controller.clear();
                      vm.onQueryChanged('');
                      _focusNode.requestFocus();
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            selectedCategory: state.selectedCategory,
            isOpenNow: state.isOpenNowFilter,
            minRating: state.minRating,
            sortBy: state.sortBy,
            onCategorySelect: vm.selectCategory,
            onOpenNowToggle: vm.toggleOpenNow,
            onMinRatingChange: vm.setMinRating,
            onSortByChange: vm.setSortBy,
          ),
          Expanded(
            child: _buildBody(state),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(SearchState state) {
    if (state.isLoading) return const LoadingShimmer();
    if (!state.hasSearched) {
      return _EmptyPrompt(
        recentSearches: state.recentSearches,
        onSelectHistory: (q) {
          _controller.text = q;
          _controller.selection = TextSelection.collapsed(offset: q.length);
          ref.read(searchViewModelProvider.notifier).searchByQuery(q);
        },
        onClearHistory: () =>
            ref.read(searchViewModelProvider.notifier).clearHistory(),
        onCategoryTap: (cat) {
          ref.read(searchViewModelProvider.notifier).selectCategory(cat);
          ref.read(searchViewModelProvider.notifier).searchByQuery('');
        },
      );
    }
    if (state.error != null) {
      return _ErrorView(
        error: state.error!,
        onRetry: () => ref.read(searchViewModelProvider.notifier).searchByQuery(
              _controller.text,
            ),
      );
    }
    if (state.results.isEmpty) return const _NoResults();
    return _ResultList(facilities: state.results, count: state.results.length);
  }
}

// ─────────────────────────────────────────────────
// フィルターバー
// ─────────────────────────────────────────────────
class _FilterBar extends ConsumerWidget {
  final String? selectedCategory;
  final bool isOpenNow;
  final double? minRating;
  final String sortBy;
  final void Function(String?) onCategorySelect;
  final VoidCallback onOpenNowToggle;
  final void Function(double?) onMinRatingChange;
  final void Function(String) onSortByChange;

  const _FilterBar({
    required this.selectedCategory,
    required this.isOpenNow,
    required this.minRating,
    required this.sortBy,
    required this.onCategorySelect,
    required this.onOpenNowToggle,
    required this.onMinRatingChange,
    required this.onSortByChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // カテゴリ + 営業中
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: AppConstants.facilityCategories.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return _CategoryChip(
                            label: 'すべて',
                            icon: Icons.apps_rounded,
                            isSelected: selectedCategory == null,
                            onTap: () => onCategorySelect(null),
                          );
                        }
                        final cat = AppConstants.facilityCategories[i - 1];
                        return _CategoryChip(
                          label: AppConstants.categoryNames[cat]!,
                          icon: AppConstants.categoryIcons[cat]!,
                          isSelected: selectedCategory == cat,
                          onTap: () => onCategorySelect(
                              selectedCategory == cat ? null : cat),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ToggleChip(
                  icon: Icons.access_time_rounded,
                  label: '営業中',
                  isActive: isOpenNow,
                  onTap: onOpenNowToggle,
                ),
              ],
            ),
          ),
          // 評価フィルター + ソート
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _RatingChip(
                          label: '★3以上',
                          isSelected: minRating == 3.0,
                          onTap: () => onMinRatingChange(minRating == 3.0 ? null : 3.0),
                        ),
                        _RatingChip(
                          label: '★4以上',
                          isSelected: minRating == 4.0,
                          onTap: () => onMinRatingChange(minRating == 4.0 ? null : 4.0),
                        ),
                        _RatingChip(
                          label: '★4.5以上',
                          isSelected: minRating == 4.5,
                          onTap: () => onMinRatingChange(minRating == 4.5 ? null : 4.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SortButton(sortBy: sortBy, onChanged: onSortByChange),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String sortBy;
  final void Function(String) onChanged;
  const _SortButton({required this.sortBy, required this.onChanged});

  String get _label => sortBy == 'rating' ? '評価順' : sortBy == 'new' ? '新着順' : '並び替え';
  bool get _isActive => sortBy != 'default';

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (ctx) => [
        _menuItem('default', 'デフォルト', Icons.sort_rounded, sortBy),
        _menuItem('rating', '評価順', Icons.star_rounded, sortBy),
        _menuItem('new', '新着順', Icons.fiber_new_rounded, sortBy),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _isActive ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isActive ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded,
                size: 15,
                color: _isActive ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              _label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded,
                size: 14,
                color: _isActive ? AppColors.primary : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, String label, IconData icon, String current) {
    final selected = current == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? AppColors.primary : AppColors.textPrimary)),
          if (selected) ...[
            const Spacer(),
            const Icon(Icons.check_rounded,
                size: 16, color: AppColors.primary),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// チップ類
// ─────────────────────────────────────────────────
class _ToggleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _ToggleChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.divider,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 6)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isActive ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _RatingChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.rating.withValues(alpha: 0.12) : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.rating : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.rating.withValues(alpha: 0.2), blurRadius: 4)]
              : null,
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
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.rating : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 6)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// 検索結果リスト（件数ヘッダー付き）
// ─────────────────────────────────────────────────
class _ResultList extends ConsumerWidget {
  final List<dynamic> facilities;
  final int count;
  const _ResultList({required this.facilities, required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider).valueOrNull ?? [];
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final location = ref.watch(currentLocationProvider).valueOrNull;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: facilities.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '$count件の施設が見つかりました',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        final facility = facilities[i - 1];
        final isFav = favorites.any((f) => f.facilityId == facility.id);
        final distKm = location != null
            ? haversineKm(
                location.latitude,
                location.longitude,
                facility.latitude,
                facility.longitude,
              )
            : null;
        return FacilityCard(
          facility: facility,
          isFavorite: isFav,
          distanceKm: distKm,
          onTap: () => context.push('/facility/${facility.id}'),
          onFavoriteTap: user == null
              ? null
              : () =>
                  ref.read(favoriteNotifierProvider.notifier).toggle(facility),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────
// 検索前プロンプト（履歴 + カテゴリクイックアクセス）
// ─────────────────────────────────────────────────
class _EmptyPrompt extends StatelessWidget {
  final List<String> recentSearches;
  final void Function(String) onSelectHistory;
  final VoidCallback onClearHistory;
  final void Function(String) onCategoryTap;

  const _EmptyPrompt({
    required this.recentSearches,
    required this.onSelectHistory,
    required this.onClearHistory,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        if (recentSearches.isEmpty) ...[
          // ── アイコン + ヒント ──
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'キーワードで検索',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '施設名・エリアを入力してください',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ] else ...[
          // ── 検索履歴 ──
          Row(
            children: [
              const Icon(Icons.history_rounded,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Text(
                '最近の検索',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClearHistory,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Text(
                    '全削除',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recentSearches.map(
            (q) => _HistoryItem(
              query: q,
              onTap: () => onSelectHistory(q),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── カテゴリクイックアクセス ──
        const Text(
          'カテゴリから探す',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: AppConstants.facilityCategories.map((cat) {
            final name = AppConstants.categoryNames[cat]!;
            final icon = AppConstants.categoryIcons[cat]!;
            return _QuickCategoryCard(
              label: name,
              icon: icon,
              onTap: () => onCategoryTap(cat),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  const _HistoryItem({required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_rounded,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    query,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary),
                  ),
                ),
                const Icon(Icons.north_west_rounded,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickCategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickCategoryCard(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// 検索結果なし
// ─────────────────────────────────────────────────
class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '施設が見つかりませんでした',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'キーワードやカテゴリを\n変えて試してみてください',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const _SearchTip(icon: Icons.lightbulb_outline_rounded, text: '別のキーワードで検索'),
            const SizedBox(height: 8),
            const _SearchTip(icon: Icons.filter_alt_off_rounded, text: 'フィルターを外してみる'),
            const SizedBox(height: 8),
            const _SearchTip(icon: Icons.apps_rounded, text: 'カテゴリを「すべて」に戻す'),
          ],
        ),
      ),
    );
  }
}

class _SearchTip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SearchTip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(text,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// エラー表示
// ─────────────────────────────────────────────────
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '接続エラー',
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
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('再試行'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
