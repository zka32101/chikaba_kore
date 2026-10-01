// クチコミへの「参考になった」投票が作成されたら、親レビューの累計件数
// （helpfulCount）をインクリメントする。二重投票はfirestore.rules側
// （helpfulVotes/{userId}をdocIdとする設計）で防止済みのため、ここでは
// 1回のonCreateにつき必ず+1してよい。
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

export const onReviewHelpfulVoteCreate = functions.firestore
  .document('reviews/{reviewId}/helpfulVotes/{userId}')
  .onCreate(async (_snap, context) => {
    const reviewId = context.params.reviewId as string;
    await admin
      .firestore()
      .collection('reviews')
      .doc(reviewId)
      .update({ helpfulCount: admin.firestore.FieldValue.increment(1) });
  });
