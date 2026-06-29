import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/facility_model.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../view_models/home_view_model.dart';
import '../../config/theme/app_theme.dart';
import '../../utils/extensions.dart';
import '../widgets/facility_card.dart';

class HomeReelTab extends ConsumerWidget {
  final List<FacilityModel> facilities;
  const HomeReelTab({super.key, required this.facilities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider).valueOrNull ?? [];
    final favoriteIds = favorites.map((f) => f.facilityId).toSet();
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final homeState = ref.watch(homeViewModelProvider);
    final location = ref.watch(currentLocationProvider).valueOrNull;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      // +1: フッター（ローディング or "以上"）
      itemCount: facilities.length + 1,
      itemBuilder: (_, i) {
        if (i == facilities.length) {
          // 末尾に到達したら loadMore をトリガー
          if (homeState.hasMore && !homeState.isLoadingMore) {
            Future.microtask(
              () => ref.read(homeViewModelProvider.notifier).loadMore(),
            );
          }
          if (homeState.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          if (!homeState.hasMore) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'すべて表示しました',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }
        final facility = facilities[i];
        final distKm = location != null
            ? haversineKm(
                location.latitude, location.longitude,
                facility.latitude, facility.longitude,
              )
            : null;
        return FacilityCard(
          facility: facility,
          isFavorite: favoriteIds.contains(facility.id),
          distanceKm: distKm,
          onTap: () => context.push('/facility/${facility.id}'),
          onFavoriteTap: user == null
              ? null
              : () => ref.read(favoriteNotifierProvider.notifier).toggle(facility),
        );
      },
    );
  }
}
