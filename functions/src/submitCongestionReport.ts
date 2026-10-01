// 施設の「今の混雑状況」投稿Callable Function。
//
// `congestionReports`のfirestore.rulesは`allow create: if false`でクライアントからの
// 直接作成を禁止しているため（連投レート制限をクライアントが回避できてしまうため）、
// 投稿は本Function経由で行う。クチコミ等とは異なり主観的な実況情報であり承認制は不要なため、
// レート制限のみを適用しそのまま即時反映する。
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { checkAndIncrementRateLimit } from './spotRateLimiting';

export const CONGESTION_RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000; // 同一施設への連投を防ぐため10分間は1回まで
export const CONGESTION_RATE_LIMIT_MAX_REQUESTS = 1;

export const CONGESTION_LEVELS = ['empty', 'normal', 'crowded'] as const;
export type CongestionLevel = (typeof CONGESTION_LEVELS)[number];

export function isValidCongestionLevel(value: unknown): value is CongestionLevel {
  return typeof value === 'string' && (CONGESTION_LEVELS as readonly string[]).includes(value);
}

export const submitCongestionReport = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'サインインが必要です');
  }
  const uid = context.auth.uid;

  const { facilityId, level } = (data ?? {}) as { facilityId?: string; level?: string };
  if (typeof facilityId !== 'string' || facilityId.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'facilityIdが不正です');
  }
  if (!isValidCongestionLevel(level)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `levelは${CONGESTION_LEVELS.join('/')}のいずれかである必要があります`
    );
  }

  const db = admin.firestore();
  const allowed = await checkAndIncrementRateLimit(db, `congestion:${uid}:${facilityId}`, {
    windowMs: CONGESTION_RATE_LIMIT_WINDOW_MS,
    maxRequests: CONGESTION_RATE_LIMIT_MAX_REQUESTS,
    now: new Date(),
  });
  if (!allowed) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      '同じ施設への投稿は少し時間を空けてから行ってください'
    );
  }

  await db.collection('congestionReports').add({
    facilityId,
    level,
    submitterId: uid,
    createdAt: admin.firestore.Timestamp.now(),
  });

  return { success: true };
});
