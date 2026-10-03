import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

/**
 * クチコミへの返信が作成されたら、親クチコミの累計件数（replyCount）を
 * インクリメントする（onReviewHelpfulVoteCreateと同じ設計）。
 */
export const onReviewReplyCreate = functions.firestore
  .document('reviews/{reviewId}/replies/{replyId}')
  .onCreate(async (_snap, context) => {
    const reviewId = context.params.reviewId as string;
    await admin
      .firestore()
      .collection('reviews')
      .doc(reviewId)
      .update({ replyCount: admin.firestore.FieldValue.increment(1) });
  });
