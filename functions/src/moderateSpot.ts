// 投稿（shadeSpots/brightnessSpots）の人力承認/却下Callable Function（あんしんみち由来の
// クチコミ承認UIパターンをスポット投稿系にも展開）。
//
// shadeSpots/brightnessSpotsのfirestore.rulesは`allow update, delete: if false`で
// クライアントからの直接更新を一切禁止しているため（`onSpotCreate.ts`参照）、管理者による
// 人力承認もCallable Function（Admin SDK、ルールの制約を受けない）経由で行う。
// 承認（statusを'approved'に更新）すると、既存の`onSpotApprove.ts`のonUpdateトリガーが
// 自動的に道路区間への集計反映を行う。却下はクチコミのreject動作に合わせて削除する。
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

export type SpotKind = 'shade' | 'brightness';
export type ModerateSpotAction = 'approve' | 'reject';

export function spotCollectionName(spotKind: SpotKind): string {
  return spotKind === 'shade' ? 'shadeSpots' : 'brightnessSpots';
}

export const moderateSpot = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'サインインが必要です');
  }
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError('permission-denied', '管理者のみ実行できます');
  }

  const { spotKind, spotId, action } = (data ?? {}) as {
    spotKind?: string;
    spotId?: string;
    action?: string;
  };
  if (spotKind !== 'shade' && spotKind !== 'brightness') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'spotKindはshadeまたはbrightnessである必要があります'
    );
  }
  if (action !== 'approve' && action !== 'reject') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'actionはapproveまたはrejectである必要があります'
    );
  }
  if (typeof spotId !== 'string' || spotId.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'spotIdが不正です');
  }

  const db = admin.firestore();
  const ref = db.collection(spotCollectionName(spotKind)).doc(spotId);

  if (action === 'approve') {
    await ref.update({ status: 'approved' });
  } else {
    await ref.delete();
  }

  return { success: true };
});
