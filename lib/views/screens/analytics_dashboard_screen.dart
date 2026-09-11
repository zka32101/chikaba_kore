import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/analytics_provider.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(analyticsPeriodProvider);
    final summaryAsync = ref.watch(analyticsSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分析ダッシュボード'),
        elevation: 0,
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラーが発生しました: $error'),
        ),
        data: (summary) {
          if (summary == null) {
            return const Center(
              child: Text('データがありません'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period selector
                _buildPeriodSelector(context, ref, period),
                const SizedBox(height: 24),

                // Key metrics cards
                _buildKeyMetricsSection(summary),
                const SizedBox(height: 24),

                // User activity section
                _buildUserActivitySection(context, ref),
                const SizedBox(height: 24),

                // Facility analytics section
                _buildFacilityAnalyticsSection(context, ref),
                const SizedBox(height: 24),

                // Event analytics section
                _buildEventAnalyticsSection(context, ref),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context,
    WidgetRef ref,
    AnalyticsPeriod period,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final p in AnalyticsPeriod.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(p.label),
                  selected: period == p,
                  onSelected: (_) =>
                      ref.read(analyticsPeriodProvider.notifier).state = p,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsSection(AnalyticsSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'キーメトリクス',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildMetricCard(
                'アクティブユーザー\n(本日)',
                summary.activeUsersToday.toString(),
                Icons.people,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                'アクティブユーザー\n(週間)',
                summary.activeUsersThisWeek.toString(),
                Icons.groups,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                '合計ユーザー',
                summary.totalUsers.toString(),
                Icons.person_add,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                'セッション(本日)',
                summary.sessionsToday.toString(),
                Icons.timer,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildMetricCard(
                '施設総数',
                summary.totalFacilities.toString(),
                Icons.location_on,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                'レビュー総数',
                summary.totalReviews.toString(),
                Icons.star,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                '平均評価',
                '${summary.averagePlatformRating.toStringAsFixed(1)} ⭐',
                Icons.favorite,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                '平均セッション\n時間',
                _formatDuration(summary.averageSessionDuration),
                Icons.schedule,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUserActivitySection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ユーザーアクティビティ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityRow('検索された施設', Icons.search),
              const Divider(),
              _buildActivityRow('投稿されたレビュー', Icons.comment),
              const Divider(),
              _buildActivityRow('追加されたお気に入り', Icons.favorite_border),
              const Divider(),
              _buildActivityRow('ユーザー登録', Icons.person_add),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRow(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue),
              const SizedBox(width: 12),
              Text(label),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '↑ 15%',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityAnalyticsSection(BuildContext context, WidgetRef ref) {
    final topFacilitiesAsync = ref.watch(topFacilitiesByViewsProvider(10));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '人気の施設',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        topFacilitiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('エラー: $error')),
          data: (facilities) {
            if (facilities.isEmpty) {
              return const Center(child: Text('データなし'));
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: facilities.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final facility = facilities[index];
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}. ${facility.facilityId}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '閲覧: ${facility.totalViews} | レビュー: ${facility.totalReviews}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '⭐ ${facility.averageRating.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEventAnalyticsSection(BuildContext context, WidgetRef ref) {
    final period = ref.watch(analyticsPeriodProvider);
    final (startDate, endDate) = period.getDateRange();
    final eventCountsAsync = ref.watch(eventCountsProvider((startDate, endDate)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'イベント分析',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        eventCountsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('エラー: $error')),
          data: (eventCounts) {
            if (eventCounts.isEmpty) {
              return const Center(child: Text('データなし'));
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: eventCounts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final entries = eventCounts.entries.toList();
                  final entry = entries[index];
                  final percentage =
                      eventCounts.values.isEmpty
                          ? 0.0
                          : (entry.value / eventCounts.values.reduce((a, b) => a + b))
                              .toDouble();

                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${entry.value}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 8,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue[300],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}
