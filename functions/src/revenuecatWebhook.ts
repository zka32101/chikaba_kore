// RevenueCat の Server Notifications (Webhook) を受信し、
// Firestore の users/{uid}.isPremium を更新する。
//
// 【設定手順】
//   1. RevenueCat ダッシュボード → Project Settings → Integrations → Webhooks
//   2. URL にこの関数のデプロイ先URLを設定
//   3. Authorization header に秘密文字列を設定し、同じ値を Cloud Functions の
//      環境変数 REVENUECAT_WEBHOOK_SECRET に設定する
//
// app_user_id は Firebase Auth の uid と一致する前提（クライアント側で
// Purchases.logIn(uid) を呼んでいる。lib/purchases/purchases_bootstrap.dart 参照）。
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

export interface RevenueCatWebhookEvent {
  type: string;
  app_user_id: string;
  product_id?: string;
}

export interface RevenueCatWebhookPayload {
  api_version: string;
  event: RevenueCatWebhookEvent;
}

// プレミアム状態を付与するイベント種別
const PREMIUM_GRANT_EVENTS = new Set([
  'INITIAL_PURCHASE',
  'RENEWAL',
  'UNCANCELLATION',
  'PRODUCT_CHANGE',
]);

// プレミアム状態を剥奪するイベント種別
// (CANCELLATIONは自動更新の停止のみで即座には失効しないため対象外。
//  実際の失効はEXPIRATIONイベントで通知される)
const PREMIUM_REVOKE_EVENTS = new Set(['EXPIRATION']);

/**
 * イベント種別からプレミアム状態の更新方針を決定する純関数。
 * true=付与, false=剥奪, null=このイベントでは状態を変更しない
 */
export function decidePremiumUpdate(eventType: string): boolean | null {
  if (PREMIUM_GRANT_EVENTS.has(eventType)) return true;
  if (PREMIUM_REVOKE_EVENTS.has(eventType)) return false;
  return null;
}

export const revenuecatWebhook = functions.https.onRequest(async (req, res) => {
  const expectedSecret = process.env.REVENUECAT_WEBHOOK_SECRET;

  if (!expectedSecret) {
    functions.logger.error('REVENUECAT_WEBHOOK_SECRET is not configured');
    res.status(500).send('Server misconfigured');
    return;
  }

  const authHeader = req.get('Authorization');
  if (authHeader !== `Bearer ${expectedSecret}`) {
    functions.logger.warn('revenuecatWebhook: unauthorized request');
    res.status(401).send('Unauthorized');
    return;
  }

  const payload = req.body as RevenueCatWebhookPayload;
  const event = payload?.event;

  if (!event?.app_user_id || !event?.type) {
    functions.logger.warn('revenuecatWebhook: malformed payload');
    res.status(400).send('Malformed payload');
    return;
  }

  const grant = decidePremiumUpdate(event.type);
  if (grant === null) {
    functions.logger.info(`revenuecatWebhook: ignored event type ${event.type}`);
    res.status(200).send('Ignored');
    return;
  }

  const uid = event.app_user_id;
  try {
    await admin.firestore().collection('users').doc(uid).update({
      isPremium: grant,
      premiumUpdatedAt: admin.firestore.Timestamp.now(),
      premiumProduct: grant ? event.product_id ?? null : null,
    });
    functions.logger.info(
      `revenuecatWebhook: ${grant ? 'granted' : 'revoked'} premium for ${uid} (${event.type})`
    );
    res.status(200).send('OK');
  } catch (error) {
    functions.logger.error('revenuecatWebhook: failed to update Firestore', error);
    res.status(500).send('Internal error');
  }
});
