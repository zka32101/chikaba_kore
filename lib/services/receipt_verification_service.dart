import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../utils/logger.dart';

/// App StoreおよびGoogle Playでの購入レシート検証
class ReceiptVerificationService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// 購入を検証してpremiumステータスを更新
  ///
  /// Returns: 検証成功時 true
  Future<bool> verifyPurchaseAndUpdatePremium(
    PurchaseDetails purchase,
  ) async {
    try {
      appLogger.i('Verifying purchase: ${purchase.productID}');

      // サーバー側のCloud Functionを呼び出して検証
      final result = await _functions
          .httpsCallable('verifyPurchaseReceipt')
          .call<Map<String, dynamic>>({
        'productId': purchase.productID,
        'verificationData': {
          'localVerificationData': purchase.verificationData.localVerificationData,
          'serverVerificationData': purchase.verificationData.serverVerificationData,
          'source': purchase.verificationData.source,
        },
      });

      final success = result.data['success'] as bool;
      if (success) {
        appLogger.i('Purchase verified successfully: ${purchase.productID}');
      } else {
        appLogger.w('Purchase verification failed: ${result.data['error']}');
      }
      return success;
    } on FirebaseFunctionsException catch (e) {
      appLogger.e('Verification error: ${e.code}', error: e);
      return false;
    } catch (e) {
      appLogger.e('Unexpected error during verification', error: e);
      return false;
    }
  }

  /// 複数の購入を一括検証
  Future<List<PurchaseDetails>> verifyPurchases(
    List<PurchaseDetails> purchases,
  ) async {
    final verified = <PurchaseDetails>[];

    for (final purchase in purchases) {
      if (await verifyPurchaseAndUpdatePremium(purchase)) {
        verified.add(purchase);
      }
    }

    return verified;
  }
}
