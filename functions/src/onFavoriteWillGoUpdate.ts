import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { shouldIncrementVisitOnFavoriteWrite } from './visitStats';

/**
 * お気に入り（facilityへの「行きたい」/「行ってきた」タグ）の作成・更新時に、
 * statusが'will_go'（行ってきた）に"なった"タイミングのみ「訪問」実績
 * （users/{userId}.visitCount）を+1する。判定ロジックはvisitStats.tsに分離。
 */
export const onFavoriteWillGoUpdate = functions.firestore
  .document('users/{userId}/favorites/{favoriteId}')
  .onWrite(async (change, context) => {
    const beforeStatus = change.before.exists
      ? (change.before.data()!.status as string | undefined)
      : undefined;
    const afterStatus = change.after.exists
      ? (change.after.data()!.status as string | undefined)
      : undefined;

    if (!shouldIncrementVisitOnFavoriteWrite(beforeStatus, afterStatus)) return;

    const userId = context.params.userId as string;
    await admin
      .firestore()
      .collection('users')
      .doc(userId)
      .update({ visitCount: admin.firestore.FieldValue.increment(1) });
  });
