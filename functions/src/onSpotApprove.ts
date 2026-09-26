// 人力承認（管理コンソール等でstatusをpending→approvedへ更新した場合）でも、
// 新規作成時（onSpotCreate.ts）と同じ集計ロジックを適用する（あんしんみち由来）。
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { applyApprovedSpotToRoadSegment, computeTrustWeight } from './spotAggregation';

type SpotKind = 'shade' | 'brightness';

async function handleSpotApproved(
  change: functions.Change<admin.firestore.QueryDocumentSnapshot>,
  spotKind: SpotKind
): Promise<void> {
  const before = change.before.data();
  const after = change.after.data();
  if (before.status === after.status || after.status !== 'approved') return;

  const db = admin.firestore();
  const userDoc = await db.collection('users').doc(after.submitterId).get();
  const trustWeight = computeTrustWeight(
    userDoc.exists ? (userDoc.data() as { isVerified?: boolean }) : undefined
  );
  await applyApprovedSpotToRoadSegment(
    db,
    after.roadSegmentId,
    spotKind === 'brightness' ? { brightness: 0 } : { shade: 1 },
    trustWeight
  );
}

export const onShadeSpotApproved = functions.firestore
  .document('shadeSpots/{spotId}')
  .onUpdate(async (change) => {
    await handleSpotApproved(change, 'shade');
  });

export const onBrightnessSpotApproved = functions.firestore
  .document('brightnessSpots/{spotId}')
  .onUpdate(async (change) => {
    await handleSpotApproved(change, 'brightness');
  });
