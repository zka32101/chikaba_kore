import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../providers/billing_provider.dart';
import '../../providers/auth_provider.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingAvailable = ref.watch(billingAvailableProvider);
    final products = ref.watch(billingProductsProvider);
    final billingState = ref.watch(billingNotifierProvider);
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

              // ビリング利用可能性チェック
              billingAvailable.when(
                data: (available) {
                  if (!available) {
                    return Center(
                      child: Text(
                        'このデバイスではアプリ内課金がご利用いただけません',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    );
                  }

                  // 商品一覧
                  return products.when(
                    data: (productList) {
                      if (productList.isEmpty) {
                        return const Center(
                          child: Text('利用可能な商品がありません'),
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
                          ...productList.map(
                            (product) => _buildProductCard(
                              context,
                              ref,
                              product,
                              billingState,
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
                  onPressed: billingState.isLoading
                      ? null
                      : () => _handleRestore(context, ref),
                  child: billingState.isLoading
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

  Widget _buildProductCard(
    BuildContext context,
    WidgetRef ref,
    ProductDetails product,
    AsyncValue<void> billingState,
  ) {
    final isMonthly = product.id.contains('monthly');
    final isLoading = billingState.isLoading;

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
              product.price,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!isMonthly)
              Text(
                '月額 ${(double.parse(product.price.replaceAll(RegExp(r'[^0-9.]'), '')) / 12).toStringAsFixed(2)} 相当',
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
                    : () => _handlePurchase(context, ref, product),
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
    ProductDetails product,
  ) async {
    try {
      final notifier = ref.read(billingNotifierProvider.notifier);
      final success = await notifier.purchaseProduct(product);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('購入処理が開始されました')),
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
      final notifier = ref.read(billingNotifierProvider.notifier);
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
