import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../config/theme/app_theme.dart';
import '../models/facility_model.dart';
import '../models/user_model.dart';
import '../view_models/facility_detail_view_model.dart';
import 'fullscreen_image_screen.dart';
import '../providers/favorite_provider.dart';
import '../providers/auth_provider.dart';
import 'widgets/review_item.dart';
import 'widgets/loading_shimmer.dart';

class FacilityDetailScreen extends ConsumerWidget {
  final String facilityId;
  const FacilityDetailScreen({super.key, required this.facilityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(facilityDetailViewModelProvider(facilityId));

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.primary),
        body: const LoadingShimmer(),
      );
    }
    if (state.facility == null) {
      return _ErrorScreen(
        error: state.error,
        onRetry: () => ref
            .read(facilityDetailViewModelProvider(facilityId).notifier)
            .refresh(),
      );
    }

    final facility = state.facility!;
    final favorites = ref.watch(favoritesProvider).valueOrNull ?? [];
    final isFav = favorites.any((f) => f.facilityId == facilityId);
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref
            .read(facilityDetailViewModelProvider(facilityId).notifier)
            .refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context, facility, isFav, user, ref),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfo(context, facility),
                  _buildQuickActions(context, facility),
                  const _SectionDivider(),
                  _buildBusinessHours(context, facility),
                  if (facility.businessHours.isNotEmpty) const _SectionDivider(),
                  _buildReviews(context, ref, facility, state, user),
                  const SizedBox(height: 80), // FABとの余白
                ],
              ),
            ),
          ],
        ),
      ),
      // クチコミ投稿FAB
      floatingActionButton: user != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                final posted = await context.push<bool>(
                  Uri(
                    path: '/facility/${facility.id}/review',
                    queryParameters: {'name': facility.name},
                  ).toString(),
                );
                if (posted == true) {
                  await ref
                      .read(facilityDetailViewModelProvider(facility.id).notifier)
                      .refreshReviews();
                }
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text(
                'クチコミを書く',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              elevation: 4,
            )
          : null,
    );
  }

  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    FacilityModel facility,
    bool isFav,
    UserModel? user,
    WidgetRef ref,
  ) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.4),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: _ImageGallery(imageUrls: facility.imageUrls),
      ),
      actions: [
        _AppBarIconButton(
          icon: Icons.share_rounded,
          onTap: () => _shareFacility(facility),
        ),
        if (user != null)
          _AppBarIconButton(
            icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFav ? AppColors.accent : Colors.white,
            onTap: () =>
                ref.read(favoriteNotifierProvider.notifier).toggle(facility),
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _shareFacility(FacilityModel facility) {
    final mapsUrl =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(facility.address)}';
    Share.share(
      '【${facility.name}】\n${facility.address}\n評価: ★${facility.averageRating.toStringAsFixed(1)} (${facility.reviewCount}件)\n$mapsUrl\n#近場コレ',
      subject: facility.name,
    );
  }

  Widget _buildBasicInfo(BuildContext context, FacilityModel facility) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 施設名 + 営業中バッジ
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  facility.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              if (facility.isOpenNow)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B377).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00B377).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 7, color: Color(0xFF00B377)),
                      SizedBox(width: 5),
                      Text(
                        '営業中',
                        style: TextStyle(
                          color: Color(0xFF00B377),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // 評価
          Row(
            children: [
              ...List.generate(5, (i) {
                final filled = i < facility.averageRating.round();
                return Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppColors.rating,
                  size: 20,
                );
              }),
              const SizedBox(width: 8),
              Text(
                facility.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${facility.reviewCount}件のレビュー)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          if (facility.eccentricityScore > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('💎', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '穴波スコア ${facility.eccentricityScore.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.localBadge.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.localBadge.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '地元民 ${facility.localReviewRatio.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.localBadge,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (facility.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              facility.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ],
      ),
    );
  }

  // 住所・電話・Webをタップしやすいカード形式で
  Widget _buildQuickActions(BuildContext context, FacilityModel facility) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.location_on_rounded,
            iconColor: AppColors.primary,
            title: facility.address,
            subtitle: 'Google Maps で開く',
            trailing: Icons.open_in_new_rounded,
            onTap: () {
              final query = Uri.encodeComponent(facility.address);
              launchUrl(
                Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=$query'),
                mode: LaunchMode.externalApplication,
              );
            },
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: facility.address));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('住所をコピーしました'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          if (facility.phone.isNotEmpty)
            _ActionTile(
              icon: Icons.phone_rounded,
              iconColor: const Color(0xFF4A90D9),
              title: facility.phone,
              subtitle: 'タップして電話をかける',
              trailing: Icons.call_rounded,
              onTap: () => launchUrl(Uri.parse('tel:${facility.phone}')),
            ),
          if (facility.website != null)
            _ActionTile(
              icon: Icons.language_rounded,
              iconColor: const Color(0xFF9B59B6),
              title: 'ウェブサイト',
              subtitle: facility.website!,
              trailing: Icons.open_in_new_rounded,
              onTap: () => launchUrl(
                Uri.parse(facility.website!),
                mode: LaunchMode.externalApplication,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBusinessHours(BuildContext context, FacilityModel facility) {
    if (facility.businessHours.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final todayKey = _weekdayKey(now.weekday);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('営業時間', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: facility.businessHours.entries.map((e) {
                final isToday = e.key == todayKey;
                return Container(
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primary.withValues(alpha: 0.06)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text(
                          e.key,
                          style: TextStyle(
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 13,
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 13,
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isToday ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                      if (isToday)
                        const Text(
                          '今日',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayKey(int weekday) {
    const keys = ['月', '火', '水', '木', '金', '土', '日'];
    return keys[(weekday - 1) % 7];
  }

  Widget _buildReviews(
    BuildContext context,
    WidgetRef ref,
    FacilityModel facility,
    FacilityDetailState detailState,
    UserModel? user,
  ) {
    final visibleReviews = detailState.visibleReviews;
    final totalCount = detailState.reviews.length;
    final filteredCount = detailState.filteredReviewCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('クチコミ', style: Theme.of(context).textTheme.titleMedium),
              if (totalCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$totalCount件',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (totalCount > 0) ...[
            // フィルター・ソート行
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _RatingFilterChip(
                          label: 'すべて',
                          isSelected: detailState.reviewMinRating == null,
                          onTap: () => ref
                              .read(facilityDetailViewModelProvider(facility.id)
                                  .notifier)
                              .setMinRating(null),
                        ),
                        _RatingFilterChip(
                          label: '★3以上',
                          isSelected: detailState.reviewMinRating == 3.0,
                          onTap: () => ref
                              .read(facilityDetailViewModelProvider(facility.id)
                                  .notifier)
                              .setMinRating(3.0),
                        ),
                        _RatingFilterChip(
                          label: '★4以上',
                          isSelected: detailState.reviewMinRating == 4.0,
                          onTap: () => ref
                              .read(facilityDetailViewModelProvider(facility.id)
                                  .notifier)
                              .setMinRating(4.0),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SortMenu(
                  sortBy: detailState.reviewSortBy,
                  onChanged: (v) => ref
                      .read(facilityDetailViewModelProvider(facility.id)
                          .notifier)
                      .setSortBy(v),
                ),
              ],
            ),
            if (filteredCount != totalCount)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '$filteredCount件表示中',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
          ],
          if (detailState.isLoadingReviews)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
            )
          else if (visibleReviews.isEmpty)
            _EmptyReviews(user: user, facility: facility)
          else ...[
            ...visibleReviews.map((r) => ReviewItem(review: r)),
            if (detailState.hasMoreReviews)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: InkWell(
                  onTap: () => ref
                      .read(facilityDetailViewModelProvider(facilityId)
                          .notifier)
                      .loadMoreReviews(),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.expand_more_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'もっと読む  (残り${filteredCount - detailState.reviewDisplayCount}件)',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// まだクチコミなし表示
class _EmptyReviews extends StatelessWidget {
  final UserModel? user;
  final FacilityModel facility;
  const _EmptyReviews({required this.user, required this.facility});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.divider.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('📝', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          const Text(
            'まだクチコミはありません',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '最初のクチコミを書いてみましょう',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// AppBar 上のアイコンボタン（半透明背景）
class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AppBarIconButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, top: 6, bottom: 6),
      child: CircleAvatar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        radius: 18,
        child: IconButton(
          icon: Icon(icon, color: color, size: 20),
          onPressed: onTap,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// タップしやすいアクション行（住所・電話・Web）
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final IconData trailing;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(trailing, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// セクション区切り
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 8, color: AppColors.background);
  }
}

/// エラー画面
class _ErrorScreen extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;
  const _ErrorScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('施設詳細')),
      body: Center(
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
                child: const Icon(Icons.error_outline_rounded,
                    size: 44, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Text(
                error != null ? 'データを読み込めませんでした' : '施設が見つかりませんでした',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('再試行'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 評価フィルターチップ
class _RatingFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RatingFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// ソート選択メニュー
class _SortMenu extends StatelessWidget {
  final String sortBy;
  final void Function(String) onChanged;

  const _SortMenu({required this.sortBy, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'new', child: Text('新着順')),
        const PopupMenuItem(value: 'rating_high', child: Text('高評価順')),
        const PopupMenuItem(value: 'rating_low', child: Text('低評価順')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded,
                color: AppColors.textSecondary, size: 16),
            const SizedBox(width: 4),
            Text(
              sortBy == 'new'
                  ? '新着'
                  : sortBy == 'rating_high'
                      ? '高評価'
                      : '低評価',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more_rounded,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  const _ImageGallery({required this.imageUrls});

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _current = 0;
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Container(
        color: AppColors.divider,
        child: const Center(
          child: Icon(Icons.storefront_outlined,
              size: 64, color: AppColors.textSecondary),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.imageUrls.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (context, i) => GestureDetector(
            onTap: () => Navigator.of(context).push(
              PageRouteBuilder(
                opaque: false,
                barrierColor: Colors.black,
                pageBuilder: (_, _, _) => FullscreenImageScreen(
                  imageUrls: widget.imageUrls,
                  initialIndex: i,
                ),
                transitionsBuilder: (_, animation, _, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            ),
            child: Hero(
              tag: 'facility_image_$i',
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[i],
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(color: AppColors.divider),
              ),
            ),
          ),
        ),
        // ボトムグラデーション
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.6, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
        ),
        // ドットインジケーター
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _current == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        // 枚数カウンター（右上）
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 14,
            right: 14,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_current + 1} / ${widget.imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
