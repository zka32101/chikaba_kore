import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { decideReviewStatus } from './reviewModeration';

const db = admin.firestore();

/**
 * クチコミ投稿時に、投稿者の直近投稿頻度を審査する。
 *
 * firestore.rules 側でクライアントは常に status: 'approved' でのみ作成できる
 * （即時公開というUXは変えない）。本トリガーは Admin SDK 経由でルールをバイパスし、
 * レート制限を超えている場合のみ事後的に status を 'pending' へ差し戻す
 * （通報・非表示フローが無いため、まずは連投対策の最小実装として導入）。
 */
export const onReviewCreate = functions.firestore
  .document('reviews/{reviewId}')
  .onCreate(async (snap) => {
    const data = snap.data();
    const userId = data.userId as string | undefined;
    if (!userId) {
      functions.logger.warn(`Review ${snap.id} has no userId, skipping moderation`);
      return;
    }

    const status = await decideReviewStatus(db, userId, new Date());
    if (status === 'pending') {
      functions.logger.info(
        `Review ${snap.id} by ${userId} exceeded rate limit, moving to pending`
      );
      await snap.ref.update({ status: 'pending' });
    }
  });
