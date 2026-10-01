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
