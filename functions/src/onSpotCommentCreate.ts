// コメント（spotComments）のモデレーション（NGワードフィルタ＋連投レート制限）。
// 本人確認要件はfirestore.rulesのisVerifiedUser()チェックで担保する（あんしんみち由来）。
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { loadModerationConfig, decideCommentModerationStatus } from './spotModeration';
import {
  checkAndIncrementRateLimit,
  COMMENT_RATE_LIMIT_WINDOW_MS,
  COMMENT_RATE_LIMIT_MAX_REQUESTS,
} from './spotRateLimiting';

export const onSpotCommentCreated = functions.firestore
  .document('spotComments/{commentId}')
  .onCreate(async (snap) => {
    const db = admin.firestore();
    const data = snap.data();
    const moderationConfig = await loadModerationConfig(db);
    let status: 'approved' | 'rejected' | 'pending' = decideCommentModerationStatus(
      data.text,
      moderationConfig.ngWords
    );

    if (status === 'approved') {
      const allowed = await checkAndIncrementRateLimit(db, `comment:${data.submitterId}`, {
        windowMs: COMMENT_RATE_LIMIT_WINDOW_MS,
        maxRequests: COMMENT_RATE_LIMIT_MAX_REQUESTS,
        now: new Date(),
      });
      if (!allowed) status = 'pending';
    }

    await snap.ref.update({ moderationStatus: status });
  });
