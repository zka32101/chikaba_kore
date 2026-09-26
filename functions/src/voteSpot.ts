// 投稿の相互チェック（確認投票／通報）Callable Function（あんしんみち由来）。
//
// 不正利用対策: (1) 投稿者本人による自演投票を禁止、(2) 同一ユーザーは同一投稿に対して
// 1回のみ投票可能（`spotVotes/{spotKind}_{spotId}_{uid}`の存在チェック、トランザクションで
// 原子的に判定）、(3) 短時間の大量投票を防ぐレート制限。
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import {
  checkAndIncrementRateLimit,
  VOTE_RATE_LIMIT_WINDOW_MS,
  VOTE_RATE_LIMIT_MAX_REQUESTS,
} from './spotRateLimiting';
import { decideSpotVoteEffect, SpotVoteType } from './spotVoting';

export const voteSpot = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'サインインが必要です');
  }
  const uid = context.auth.uid;

  const { spotKind, spotId, voteType } = (data ?? {}) as {
    spotKind?: string;
    spotId?: string;
    voteType?: string;
  };
  if (spotKind !== 'shade' && spotKind !== 'brightness') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'spotKindはshadeまたはbrightnessである必要があります'
    );
  }
  if (voteType !== 'confirm' && voteType !== 'report') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'voteTypeはconfirmまたはreportである必要があります'
    );
  }
  if (typeof spotId !== 'string' || spotId.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'spotIdが不正です');
  }

  const db = admin.firestore();
  const allowed = await checkAndIncrementRateLimit(db, `vote:${uid}`, {
    windowMs: VOTE_RATE_LIMIT_WINDOW_MS,
    maxRequests: VOTE_RATE_LIMIT_MAX_REQUESTS,
    now: new Date(),
  });
  if (!allowed) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      '短時間の投票が集中しています。しばらく待ってから再度お試しください'
    );
  }

  const spotRef = db.collection(spotKind === 'shade' ? 'shadeSpots' : 'brightnessSpots').doc(spotId);
  const voteRef = db.collection('spotVotes').doc(`${spotKind}_${spotId}_${uid}`);

  await db.runTransaction(async (tx) => {
    const [spotSnapshot, voteSnapshot] = await Promise.all([tx.get(spotRef), tx.get(voteRef)]);
    if (!spotSnapshot.exists) {
      throw new functions.https.HttpsError('not-found', '投稿が見つかりません');
    }
    const spotData = spotSnapshot.data()!;
    if (spotData.submitterId === uid) {
      throw new functions.https.HttpsError('failed-precondition', '自分の投稿には投票できません');
    }
    if (voteSnapshot.exists) {
      throw new functions.https.HttpsError('already-exists', 'この投稿にはすでに投票済みです');
    }

    const effect = decideSpotVoteEffect(
      { votes: spotData.votes ?? 0, reportCount: spotData.reportCount ?? 0, status: spotData.status },
      voteType as SpotVoteType
    );
    tx.update(spotRef, { votes: effect.votes, reportCount: effect.reportCount, status: effect.status });
    tx.set(voteRef, {
      spotKind,
      spotId,
      uid,
      voteType,
      createdAt: admin.firestore.Timestamp.now(),
    });
  });

  return { success: true };
});
