import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

const db = admin.firestore();

interface VerificationData {
  localVerificationData: string;
  serverVerificationData: string;
  source: string;
}

interface VerificationRequest {
  productId: string;
  verificationData: VerificationData;
}

/**
 * Apple App Store でのレシート検証
 */
async function verifyAppleReceipt(
  receipt: string,
  productId: string,
  isDev: boolean = false
): Promise<boolean> {
  try {
    const url = isDev
      ? 'https://sandbox.itunes.apple.com/verifyReceipt'
      : 'https://buy.itunes.apple.com/verifyReceipt';

    const response = await axios.post(url, {
      'receipt-data': receipt,
      password: process.env.APPLE_APP_SECRET || '',
    });

    const { status, receipt: receiptData } = response.data;

    // status: 0 = valid, 21007 = sandbox receipt on production, 21008 = production receipt on sandbox
    if (status === 0 || status === 21007) {
      functions.logger.info(`Apple receipt verified for ${productId}`);
      return true;
    }

    functions.logger.warn(`Apple receipt verification failed: status ${status}`);
    return false;
  } catch (error) {
    functions.logger.error('Apple receipt verification error', error);
    return false;
  }
}

/**
 * Google Play Store でのレシート検証
 */
async function verifyGoogleReceipt(
  packageName: string,
  productId: string,
  token: string
): Promise<boolean> {
  try {
    // Google Play Billing Library からのトークンを検証
    // 本番環境では Google Play API を使用
    const response = await axios.get(
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/products/${productId}/tokens/${token}`,
      {
        headers: {
          Authorization: `Bearer ${await getGoogleAccessToken()}`,
        },
      }
    );

    // purchaseState: 0 = purchased, 1 = cancelled
    if (response.data.purchaseState === 0) {
      functions.logger.info(`Google receipt verified for ${productId}`);
      return true;
    }

    functions.logger.warn(`Google receipt verification failed: not purchased`);
    return false;
  } catch (error) {
    functions.logger.error('Google receipt verification error', error);
    return false;
  }
}

/**
 * Google API アクセストークン取得
 */
async function getGoogleAccessToken(): Promise<string> {
  // Service Account 認証情報を使用
  const auth = new (require('google-auth-library').GoogleAuth)({
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  const authClient = await auth.getClient();
  const token = await authClient.getAccessToken();
  return token.token;
}

/**
 * 購入レシートを検証してプレミアムステータスを更新
 */
export const verifyPurchaseReceipt = functions.https.onCall(
  async (data: VerificationRequest, context) => {
    try {
      // ユーザー認証確認
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const uid = context.auth.uid;
      const { productId, verificationData } = data;

      functions.logger.info(
        `Verifying purchase for user ${uid}, product ${productId}`
      );

      let verified = false;

      // iOS/macOS の場合
      if (verificationData.source === 'app_store') {
        verified = await verifyAppleReceipt(
          verificationData.serverVerificationData,
          productId
        );
      }
      // Android の場合
      else if (verificationData.source === 'google_play') {
        verified = await verifyGoogleReceipt(
          'com.yourwish.chikabamap',
          productId,
          verificationData.serverVerificationData
        );
      } else {
        throw new functions.https.HttpsError(
          'invalid-argument',
          `Unknown source: ${verificationData.source}`
        );
      }

      if (verified) {
        // Firestore のユーザードキュメントを更新
        await db.collection('users').doc(uid).update({
          isPremium: true,
          premiumUpdatedAt: admin.firestore.Timestamp.now(),
          premiumProduct: productId,
        });

        functions.logger.info(`Premium status updated for user ${uid}`);

        return { success: true };
      } else {
        return {
          success: false,
          error: 'Verification failed',
        };
      }
    } catch (error) {
      functions.logger.error('Verification error', error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Verification failed'
      );
    }
  }
);
