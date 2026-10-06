import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_theme.dart';
import '../../models/favorite_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/facility_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/review_provider.dart';
import '../../utils/constants.dart';

/// プレミアム会員限定の詳細統計ダッシュボード。クチコミ投稿数・訪問実績・
/// お気に入りの内訳・投票実績をまとめて表示する。既存のマイページの統計
/// （`_ProfileStats`）は「投稿」「お気に入り」「訪問」の3件のみだったため、
/// より詳しい内訳をプレミアム特典として提供する。
class StatsDashboardScreen extends ConsumerWidget {
  const StatsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authNotifierProvider).valueOrNull;
    final isPremium = currentUser?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('詳細統計')),
      body: !isPremium ? const _PremiumRequiredView() : const _DashboardBody(),
    );
  }
}

class _PremiumRequiredView extends StatelessWidget {
  const _PremiumRequiredView();

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
              child: const Icon(Icons.workspace_premium,
                  size: 40, color: AppColors.accent),
            ),
            const SizedBox(height: 20),
            const Text(
              '詳細統計はプレミアム特典です',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'クチコミ投稿数・訪問実績・お気に入りの内訳などを\nまとめて確認できます',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/premium'),
              child: const Text('プレミアムについて見る'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsUser = ref.watch(userStatsProvider).valueOrNull;
    final favorites = ref.watch(favoritesProvider).valueOrNull ?? [];
    final wantToGoCount = favorites.where((f) => f.status == FavoriteStatus.wantToGo).length;
    final willGoCount = favorites.where((f) => f.status == FavoriteStatus.willGo).length;
    final helpfulVotedCount = ref.watch(helpfulVoteCacheProvider).length;
    final hiddenGemVotedCount = ref.watch(hiddenGemVoteCacheProvider).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.edit_outlined,
                value: '${statsUser?.reviewCount ?? 0}',
                label: 'クチコミ投稿',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.location_on_outlined,
                value: '${statsUser?.visitCount ?? 0}',
                label: '訪問実績',
                color: Colors.green,
                badge: statsUser?.visitBadgeLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.thumb_up_outlined,
                value: '$helpfulVotedCount',
                label: '「参考になった」投票',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.auto_awesome_outlined,
                value: '$hiddenGemVotedCount',
                label: '「穴場だと思う」投票',
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Text(
            '※投票実績はこの端末内の記録です。他の端末には反映されません',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 24),
        const Text('お気に入りの内訳',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _FavoriteStatusBar(wantToGoCount: wantToGoCount, willGoCount: willGoCount),
        const SizedBox(height: 24),
        const Text('カテゴリ別のお気に入り',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (favorites.isEmpty)
          const Text('お気に入りはまだありません',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
        else
          _CategoryBreakdown(favorites: favorites),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final String? badge;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          if (badge != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge!,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          ],
        ],
      ),
    );
  }
}

/// 「行きたい」/「行ってきた」の割合を表す横棒。
class _FavoriteStatusBar extends StatelessWidget {
  final int wantToGoCount;
  final int willGoCount;
  const _FavoriteStatusBar({required this.wantToGoCount, required this.willGoCount});

  @override
  Widget build(BuildContext context) {
    final total = wantToGoCount + willGoCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (total > 0)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  if (wantToGoCount > 0)
                    Expanded(
                      flex: wantToGoCount,
                      child: Container(color: AppColors.primary),
                    ),
                  if (willGoCount > 0)
                    Expanded(
                      flex: willGoCount,
                      child: Container(color: Colors.green),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            _LegendDot(color: AppColors.primary, label: '行きたい ($wantToGoCount)'),
            const SizedBox(width: 16),
            _LegendDot(color: Colors.green, label: '行ってきた ($willGoCount)'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

/// カテゴリ別のお気に入り件数を横棒グラフで表示する。
class _CategoryBreakdown extends StatelessWidget {
  final List<FavoriteModel> favorites;
  const _CategoryBreakdown({required this.favorites});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final fav in favorites) {
      counts[fav.facilityCategory] = (counts[fav.facilityCategory] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = sorted.first.value;

    return Column(
      children: sorted.map((entry) {
        final ratio = entry.value / maxCount;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  AppConstants.categoryNames[entry.key] ?? entry.key,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      children: [
                        Container(height: 18, color: AppColors.divider.withValues(alpha: 0.3)),
                        Container(
                          height: 18,
                          width: constraints.maxWidth * ratio,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 24,
                child: Text('${entry.value}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
