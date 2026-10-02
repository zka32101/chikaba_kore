// 施設への「穴場だと思う」投票が作成されたら、親施設の累計件数
// （hiddenGemVoteCount）をインクリメントする。二重投票はfirestore.rules側
// （hiddenGemVotes/{userId}をdocIdとする設計）で防止済みのため、ここでは
// 1回のonCreateにつき必ず+1してよい（onReviewHelpfulVoteCreateと同じ設計）。
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

export const onFacilityHiddenGemVoteCreate = functions.firestore
  .document('facilities/{facilityId}/hiddenGemVotes/{userId}')
  .onCreate(async (_snap, context) => {
    const facilityId = context.params.facilityId as string;
    await admin
      .firestore()
      .collection('facilities')
      .doc(facilityId)
      .update({ hiddenGemVoteCount: admin.firestore.FieldValue.increment(1) });
  });
