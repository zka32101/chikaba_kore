import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../providers/billing_provider.dart';
import '../../providers/auth_provider.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAvailable = ref.watch(purchasesAvailableProvider);
    final packages = ref.watch(availablePackagesProvider);
    final subscriptionState = ref.watch(subscriptionNotifierProvider);
    // currentUserProvider は Firestore を監視しているため、
    // RevenueCat Webhook 経由の isPremium 更新も自動反映される
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プレミアム会員'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'プレミアム会員になると',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('• 広告なし'),
                      Text('• 高度な検索フィルター'),
                      Text('• 無制限のお気に入り登録'),
                      Text('• 優先的なサポート'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (!purchasesAvailable)
                Center(
                  child: Text(
                    'このデバイスではアプリ内課金がご利用いただけません',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                )
              else
                packages.when(
                  data: (packageList) {
                    if (packageList.isEmpty) {
                      return const Center(
                        child: Text('利用可能なプランがありません'),
                      );
                    }

                    return Column(
                      children: [
                        const Text(
                          'プランを選択',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...packageList.map(
                          (package) => _buildPackageCard(
                            context,
                            ref,
                            package,
                            subscriptionState,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Text('エラー: $error'),
                  ),
                ),
              const SizedBox(height: 24),

              // 復元ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.tonal(
                  onPressed: subscriptionState.isLoading
                      ? null
                      : () => _handleRestore(context, ref),
                  child: subscriptionState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('以前の購入を復元'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    WidgetRef ref,
    Package package,
    AsyncValue<void> subscriptionState,
  ) {
    final product = package.storeProduct;
    final isMonthly = product.identifier.contains('monthly');
    final isLoading = subscriptionState.isLoading;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isMonthly ? '月額プラン' : '年額プラン',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isMonthly)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'お得',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              product.priceString,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!isMonthly)
              Text(
                '月額 ${(product.price / 12).toStringAsFixed(2)} 相当',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () => _handlePurchase(context, ref, product.identifier),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('購入する'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase(
    BuildContext context,
    WidgetRef ref,
    String productId,
  ) async {
    try {
      final notifier = ref.read(subscriptionNotifierProvider.notifier);
      final success = await notifier.purchase(productId);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('購入処理が完了しました')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }

  Future<void> _handleRestore(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final notifier = ref.read(subscriptionNotifierProvider.notifier);
      await notifier.restorePurchases();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('購入履歴を復元しました')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('復元に失敗しました: $e')),
        );
      }
    }
  }
}
