import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_theme.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../widgets/custom_app_bar.dart';

/// 承認待ち（連投レート制限に触れた等の理由で status: 'pending' となった）
/// クチコミを確認・承認/却下する管理者向け画面。
/// firestore.rules の isAdmin() でサーバー側からも権限チェックされる。
class PendingReviewsScreen extends ConsumerWidget {
  const PendingReviewsScreen({super.key});

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
    final pendingReviews = ref.watch(pendingReviewsProvider);
    final moderationState = ref.watch(reviewModerationNotifierProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: '承認待ちクチコミ'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(pendingReviewsProvider),
        child: pendingReviews.when(
          data: (reviews) {
            if (reviews.isEmpty) {
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
                          Text('承認待ちのクチコミはありません',
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
              itemCount: reviews.length,
              itemBuilder: (context, i) => _PendingReviewCard(
                review: reviews[i],
                isLoading: moderationState.isLoading,
                onApprove: () => _handleApprove(context, ref, reviews[i].id),
                onReject: () => _handleReject(context, ref, reviews[i].id),
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
    String reviewId,
  ) async {
    try {
      await ref.read(reviewModerationNotifierProvider.notifier).approve(reviewId);
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
    String reviewId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('このクチコミを却下しますか？'),
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
      await ref.read(reviewModerationNotifierProvider.notifier).reject(reviewId);
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
      appBar: const CustomAppBar(title: '承認待ちクチコミ'),
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

class _PendingReviewCard extends StatelessWidget {
  final ReviewModel review;
  final bool isLoading;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingReviewCard({
    required this.review,
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
                Expanded(
                  child: Text(
                    review.userNickname,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                ...List.generate(5, (i) {
                  final filled = i < review.rating;
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? AppColors.rating : AppColors.divider,
                    size: 15,
                  );
                }),
              ],
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => context.push('/facility/${review.facilityId}'),
              child: Text(
                '施設ID: ${review.facilityId}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(review.text, style: const TextStyle(fontSize: 13, height: 1.5)),
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
}
