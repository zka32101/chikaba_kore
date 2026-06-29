import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme/app_theme.dart';
import '../../models/facility_model.dart';
import '../../services/location_service.dart';
import '../../view_models/gacha_view_model.dart';
import '../../utils/extensions.dart';
import '../../providers/location_provider.dart';

/// ガチャ結果表示用ボトムシート
class GachaResultSheet extends ConsumerWidget {
  final VoidCallback onClose;

  const GachaResultSheet({required this.onClose, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gachaViewModelProvider);
    final location = ref.watch(currentLocationProvider).valueOrNull;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ドラッグハンドル
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // ヘッダー
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('🎰', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '今日どこ行く？',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '近場の穴場スポットをランダム提案',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // コンテンツ
                if (state.isLoading)
                  const _GachaLoading()
                else if (state.hasError && state.error != null)
                  _GachaError(
                    message: state.error!,
                    onRetry: () => ref.read(gachaViewModelProvider.notifier).spin(),
                  )
                else if (state.currentGacha != null)
                  _GachaResultCard(
                    facility: state.currentGacha!,
                    location: location,
                    onRetry: () => ref.read(gachaViewModelProvider.notifier).spin(),
                    onVisit: () {
                      final facilityId = state.currentGacha!.id;
                      context.pop();
                      context.push('/facility/$facilityId');
                    },
                  )
                else
                  _GachaInitial(
                    onSpin: () => ref.read(gachaViewModelProvider.notifier).spin(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GachaLoading extends StatefulWidget {
  const _GachaLoading();

  @override
  State<_GachaLoading> createState() => _GachaLoadingState();
}

class _GachaLoadingState extends State<_GachaLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _controller,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('🎰', style: TextStyle(fontSize: 36)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '穴場を探しています...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '800m圏内の未訪問スポットを検索中',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _GachaError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _GachaError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.divider,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, size: 36, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('もう一回'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(160, 44),
            ),
          ),
        ],
      ),
    );
  }
}

class _GachaInitial extends StatelessWidget {
  final VoidCallback onSpin;

  const _GachaInitial({required this.onSpin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // イラスト風カード
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primaryLight.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                const Text('🗺️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text(
                  '近場の穴場を\nランダムにご提案！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '未訪問 × ★4以上 × 800m圏内',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ガチャボタン
          GestureDetector(
            onTap: onSpin,
            child: Container(
              width: double.infinity,
              height: 54,
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
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('✨', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Text(
                    'ガチャを回す',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('✨', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GachaResultCard extends StatelessWidget {
  final FacilityModel facility;
  final LocationResult? location;
  final VoidCallback onRetry;
  final VoidCallback onVisit;

  const _GachaResultCard({
    required this.facility,
    required this.location,
    required this.onRetry,
    required this.onVisit,
  });

  @override
  Widget build(BuildContext context) {
    final distKm = location != null
        ? haversineKm(
            location!.latitude,
            location!.longitude,
            facility.latitude,
            facility.longitude,
          )
        : null;
    final distText = distKm != null ? formatDistance(distKm) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 施設画像（グラデーションオーバーレイ付き）
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              facility.thumbnailUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: facility.thumbnailUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
              // グラデーションオーバーレイ
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.4, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
              // 距離バッジ（右下）
              if (distText != null)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_rounded, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          distText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // 穴波バッジ（左下）
              if (facility.eccentricityScore > 0)
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💎', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(
                          '穴波 ${facility.eccentricityScore.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 施設名と住所
        Text(
          facility.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                facility.address,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 評価 + 地元民率
        Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.rating, size: 18),
            const SizedBox(width: 4),
            Text(
              facility.averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${facility.reviewCount}件)',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            if (facility.localReviewRatio > 0) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.localBadge.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.localBadge.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '地元民 ${facility.localReviewRatio.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.localBadge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),

        // ボタン
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('もう一回'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: onVisit,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_walk_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'いってきます！',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildPlaceholder() => Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Icon(Icons.storefront_outlined, size: 48, color: AppColors.textSecondary),
        ),
      );
}
