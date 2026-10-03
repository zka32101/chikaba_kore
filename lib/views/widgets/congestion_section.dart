import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme/app_theme.dart';
import '../../models/congestion_report.dart';
import '../../providers/congestion_provider.dart';

/// 施設詳細画面の「今の混雑状況」セクション。直近の投稿から集計した状況を表示し、
/// 3段階ボタンで投稿できる。
class CongestionSection extends ConsumerWidget {
  final String facilityId;
  const CongestionSection({super.key, required this.facilityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(congestionStatusProvider(facilityId));
    final hourlyPatternAsync = ref.watch(congestionHourlyPatternProvider(facilityId));
    final isSubmitting = ref.watch(congestionReportNotifierProvider).isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('今の混雑状況', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          statusAsync.when(
            data: (status) => _StatusBadge(status: status),
            loading: () => const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, _) => const Text(
              '混雑状況の取得に失敗しました',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: CongestionLevel.values
                .map(
                  (level) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: OutlinedButton(
                        onPressed: isSubmitting ? null : () => _handleSubmit(context, ref, level),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(level.label, style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          hourlyPatternAsync.when(
            data: (pattern) =>
                pattern.hasEnoughData ? _HourlyHeatmap(pattern: pattern) : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit(
    BuildContext context,
    WidgetRef ref,
    CongestionLevel level,
  ) async {
    try {
      await ref.read(congestionReportNotifierProvider.notifier).submitReport(facilityId, level);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「${level.label}」として投稿しました')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('投稿に失敗しました: $e')),
        );
      }
    }
  }
}

/// 時間帯(0-23時)別の混雑度ヒートマップ。過去の投稿から「混みやすい時間帯」
/// の傾向を24本の縦棒の濃淡で表示する。
class _HourlyHeatmap extends StatelessWidget {
  final CongestionHourlyPattern pattern;
  const _HourlyHeatmap({required this.pattern});

  Color _colorForScore(double? score) {
    if (score == null) return AppColors.divider.withValues(alpha: 0.4);
    // 0.0(空いてる・緑) → 0.5(普通・オレンジ) → 1.0(混んでる・赤)のグラデーション
    if (score <= 0.5) {
      return Color.lerp(Colors.green, Colors.orange, score / 0.5)!;
    }
    return Color.lerp(Colors.orange, AppColors.accent, (score - 0.5) / 0.5)!;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '混みやすい時間帯（直近30日間の報告から集計）',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(24, (hour) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: _colorForScore(pattern.averageScoreByHour[hour]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 3),
          Row(
            children: [0, 6, 12, 18].map((hour) {
              return Expanded(
                child: Text(
                  '$hour時',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final CongestionStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final level = status.level;
    if (level == null) {
      return const Text(
        '直近の報告はまだありません',
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      );
    }

    final color = switch (level) {
      CongestionLevel.empty => Colors.green,
      CongestionLevel.normal => Colors.orange,
      CongestionLevel.crowded => AppColors.accent,
    };

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            level.label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '直近${status.reportCount}件の報告',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
