import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

/**
 * クチコミ投稿を「訪問」実績としてカウントする。投稿者のuserIdが無い場合は
 * 何もしない（onReviewCreateのレート制限判定と同じ防御）。
 */
export const onReviewCreateUserStats = functions.firestore
  .document('reviews/{reviewId}')
  .onCreate(async (snap) => {
    const userId = snap.data().userId as string | undefined;
    if (!userId) return;

    await admin
      .firestore()
      .collection('users')
      .doc(userId)
      .update({
        reviewCount: admin.firestore.FieldValue.increment(1),
        visitCount: admin.firestore.FieldValue.increment(1),
      });
  });
