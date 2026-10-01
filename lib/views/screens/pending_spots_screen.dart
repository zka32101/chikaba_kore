import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme/app_theme.dart';
import '../../models/pending_spot.dart';
import '../../providers/auth_provider.dart';
import '../../providers/spot_provider.dart';
import '../../services/spot_vote_service.dart' show SpotVoteKind;
import '../widgets/custom_app_bar.dart';

/// 承認待ち（連投レート制限に触れた等の理由で status: 'pending' となった）
/// 投稿（安心ルートの`shadeSpots`/`brightnessSpots`）を確認・承認/却下する管理者向け画面。
/// `PendingReviewsScreen`（クチコミ）と同じ構成。Cloud Functions側（`moderateSpot`）でも
/// `admin`Custom Claimによる権限チェックが行われる。
class PendingSpotsScreen extends ConsumerWidget {
  const PendingSpotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);

    return isAdmin.when(
      data: (admin) => admin ? _buildBody(context, ref) : const _AccessDenied(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const _AccessDenied(),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final pendingSpots = ref.watch(pendingSpotsProvider);
    final moderationState = ref.watch(spotModerationNotifierProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: '承認待ち投稿（安心ルート）'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(pendingSpotsProvider),
        child: pendingSpots.when(
          data: (spots) {
            if (spots.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.task_alt_rounded,
                              size: 48, color: AppColors.textSecondary),
                          SizedBox(height: 12),
                          Text('承認待ちの投稿はありません',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: spots.length,
              itemBuilder: (context, i) => _PendingSpotCard(
                spot: spots[i],
                isLoading: moderationState.isLoading,
                onApprove: () => _handleApprove(context, ref, spots[i]),
                onReject: () => _handleReject(context, ref, spots[i]),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('読み込みエラー: $error')),
        ),
      ),
    );
  }

  Future<void> _handleApprove(
    BuildContext context,
    WidgetRef ref,
    PendingSpot spot,
  ) async {
    try {
      await ref.read(spotModerationNotifierProvider.notifier).approve(spot.kind, spot.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('承認しました')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('承認に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    WidgetRef ref,
    PendingSpot spot,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('この投稿を却下しますか？'),
        content: const Text('却下すると投稿は削除されます。この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('却下する'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(spotModerationNotifierProvider.notifier).reject(spot.kind, spot.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('却下しました')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('却下に失敗しました: $e')),
        );
      }
    }
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '承認待ち投稿（安心ルート）'),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.textSecondary),
              SizedBox(height: 12),
              Text('この画面には管理者のみアクセスできます',
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingSpotCard extends StatelessWidget {
  final PendingSpot spot;
  final bool isLoading;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingSpotCard({
    required this.spot,
    required this.isLoading,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  spot.kind == SpotVoteKind.shade ? Icons.park_outlined : Icons.light_mode_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    spot.label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            if (spot.createdAt != null) ...[
              const SizedBox(height: 6),
              Text(
                _formatRelativeTime(spot.createdAt!),
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : onReject,
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent),
                    child: const Text('却下'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onApprove,
                    child: const Text('承認'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 相対時刻表示（例:「3時間前」）。
  String _formatRelativeTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inHours < 1) return '${diff.inMinutes}分前';
    if (diff.inDays < 1) return '${diff.inHours}時間前';
    if (diff.inDays < 30) return '${diff.inDays}日前';
    return '${createdAt.year}/${createdAt.month}/${createdAt.day}';
  }
}
