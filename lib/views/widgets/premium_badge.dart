import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

/// プレミアムステータスバッジ
class PremiumBadge extends ConsumerWidget {
  final double size;
  final Color? color;

  const PremiumBadge({
    Key? key,
    this.size = 20,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return currentUser.when(
      data: (user) {
        if (user?.isPremium == true) {
          return Container(
            padding: EdgeInsets.all(size * 0.1),
            decoration: BoxDecoration(
              color: color ?? Colors.amber.shade300,
              borderRadius: BorderRadius.circular(size * 0.5),
            ),
            child: Icon(
              Icons.star,
              size: size,
              color: Colors.amber.shade900,
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: size * 0.15,
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// プレミアム会員情報カード
class PremiumInfoCard extends ConsumerWidget {
  final VoidCallback? onUpgradePressed;

  const PremiumInfoCard({
    Key? key,
    this.onUpgradePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return currentUser.when(
      data: (user) {
        if (user?.isPremium == true) {
          return Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'プレミアム会員です',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          color: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'プレミアム会員になる',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '広告なし・高度な検索機能が使用可能',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onUpgradePressed != null)
                  TextButton(
                    onPressed: onUpgradePressed,
                    child: const Text('詳細'),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('ステータスを読み込み中...'),
              ),
            ],
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
