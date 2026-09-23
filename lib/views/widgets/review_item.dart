import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/review_model.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../utils/extensions.dart';
import '../fullscreen_image_screen.dart';

class ReviewItem extends ConsumerWidget {
  final ReviewModel review;
  const ReviewItem({super.key, required this.review});

  Future<void> _handleReport(BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('このクチコミを通報しますか？'),
        content: const Text('不適切な内容として運営に報告します。一定数の通報が集まると、内容が確認されるまで非表示になります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('通報する'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(reviewReportNotifierProvider.notifier)
          .report(review.id, currentUser.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('通報しました。ご協力ありがとうございます。')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('通報に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref),
          const SizedBox(height: 10),
          _buildRating(),
          const SizedBox(height: 8),
          Text(
            review.text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.55,
            ),
          ),
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildImages(context),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 3),
              Text(
                review.createdAt.toRelativeTime(),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isOwnReview = currentUser?.uid == review.userId;
    return Row(
      children: [
        // アバター
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundImage: review.userProfileImageUrl != null
                ? CachedNetworkImageProvider(review.userProfileImageUrl!)
                : null,
            backgroundColor: AppColors.divider,
            child: review.userProfileImageUrl == null
                ? const Icon(Icons.person_rounded, size: 20, color: AppColors.textSecondary)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    review.userNickname,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (review.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded,
                        color: AppColors.primary, size: 14),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              _UserTypeBadge(isLocal: review.isLocal),
            ],
          ),
        ),
        // 自分の投稿には通報ボタンを出さない。未ログインは通報不可。
        if (currentUser != null && !isOwnReview)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                size: 18, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value == 'report') _handleReport(context, ref);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 16, color: AppColors.accent),
                    SizedBox(width: 8),
                    Text('通報する'),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRating() {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < review.rating;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: filled ? AppColors.rating : AppColors.divider,
            size: 18,
          ),
        );
      }),
    );
  }

  Widget _buildImages(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: review.imageUrls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                opaque: false,
                barrierColor: Colors.black.withValues(alpha: 0.85),
                pageBuilder: (_, _, _) => FullscreenImageScreen(
                  imageUrls: review.imageUrls,
                  initialIndex: i,
                ),
                transitionsBuilder: (_, animation, _, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            );
          },
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: review.imageUrls[i],
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.image_not_supported_outlined,
                        color: AppColors.textSecondary),
                  ),
                ),
              ),
              // タップヒント（複数枚の場合に枚数表示）
              if (i == 0 && review.imageUrls.length > 1)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_outlined,
                            size: 10, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          '${review.imageUrls.length}',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTypeBadge extends StatelessWidget {
  final bool isLocal;
  const _UserTypeBadge({required this.isLocal});

  @override
  Widget build(BuildContext context) {
    final color = isLocal ? AppColors.localBadge : AppColors.visitorBadge;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocal ? Icons.home_rounded : Icons.explore_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            isLocal ? '地元民' : '訪問者',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
