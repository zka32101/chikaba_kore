// 投稿（shadeSpots/brightnessSpots）作成時の承認/自動反映判定（あんしんみち由来）。
// クライアントは常にstatus:'pending'で作成し（firestore.rules参照）、実際の承認可否は
// ここで判定する。
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { loadModerationConfig, decideInitialStatus } from './spotModeration';
import { countRecentSpotSubmissions, exceedsSpotRateLimit } from './spotRateLimiting';
import { applyApprovedSpotToRoadSegment, computeTrustWeight } from './spotAggregation';

type SpotKind = 'shade' | 'brightness';

async function loadTrustWeight(
  db: admin.firestore.Firestore,
  submitterId: string
): Promise<number> {
  const doc = await db.collection('users').doc(submitterId).get();
  return computeTrustWeight(doc.exists ? (doc.data() as { isVerified?: boolean }) : undefined);
}

async function handleSpotCreated(
  snap: admin.firestore.QueryDocumentSnapshot,
  spotKind: SpotKind
): Promise<void> {
  const db = admin.firestore();
  const data = snap.data();
  const moderationConfig = await loadModerationConfig(db);
  // 「人通りが少ない」（brightnessSpots, reasonType: 'low_foot_traffic'）は、日陰・雨よけの
  // 有無のような客観的な観測と異なり主観的・偏見の影響を受けやすいため、地域のモデレーション
  // 設定に関わらず常に人力承認を必須とする。
  const requiresManualReview = spotKind === 'brightness' && data.reasonType === 'low_foot_traffic';
  let status = decideInitialStatus(moderationConfig, { requiresManualReview });

  if (status === 'approved') {
    const recentCount = await countRecentSpotSubmissions(db, data.submitterId, new Date());
    if (exceedsSpotRateLimit(recentCount)) {
      status = 'pending'; // レート制限超過。人力承認キューへ留め置く
    }
  }

  if (status === 'approved') {
    await snap.ref.update({ status: 'approved' });
    const trustWeight = await loadTrustWeight(db, data.submitterId);
    await applyApprovedSpotToRoadSegment(
      db,
      data.roadSegmentId,
      spotKind === 'brightness' ? { brightness: 0 } : { shade: 1 },
      trustWeight
    );
  }
  // status === 'pending' の場合はクライアントが設定した値のまま（人力承認キューで後日処理）
}

export const onShadeSpotCreated = functions.firestore
  .document('shadeSpots/{spotId}')
  .onCreate(async (snap) => {
    await handleSpotCreated(snap, 'shade');
  });

export const onBrightnessSpotCreated = functions.firestore
  .document('brightnessSpots/{spotId}')
  .onCreate(async (snap) => {
    await handleSpotCreated(snap, 'brightness');
  });
