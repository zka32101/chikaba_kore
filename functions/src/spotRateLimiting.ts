// 安全ルート機能（あんしんみち由来）の投稿・コメントの不正利用対策（連投・スパムのレート制限）。
// 姉妹アプリの `rateLimiting.js` の設計を踏襲する。
import * as admin from 'firebase-admin';

export const SPOT_RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000; // 直近10分間を見る
export const SPOT_RATE_LIMIT_MAX_SUBMISSIONS = 5; // このドキュメント自身を含め、直近10分間に5件を超えたら以降は保留

/**
 * 直近`SPOT_RATE_LIMIT_WINDOW_MS`以内の投稿件数（このドキュメント自身を含む）が、
 * レート制限を超えているかどうかを判定する純関数。
 */
export function exceedsSpotRateLimit(recentSubmissionCount: number): boolean {
  return recentSubmissionCount > SPOT_RATE_LIMIT_MAX_SUBMISSIONS;
}

/**
 * `submitterId`による直近`SPOT_RATE_LIMIT_WINDOW_MS`以内の投稿件数を、shadeSpots/brightnessSpots
 * 両コレクション横断でカウントする（投稿種別を変えての連投もレート制限の対象にするため）。
 */
export async function countRecentSpotSubmissions(
  db: admin.firestore.Firestore,
  submitterId: string,
  now: Date
): Promise<number> {
  const sinceDate = admin.firestore.Timestamp.fromDate(
    new Date(now.getTime() - SPOT_RATE_LIMIT_WINDOW_MS)
  );
  const [shadeSnapshot, brightnessSnapshot] = await Promise.all([
    db
      .collection('shadeSpots')
      .where('submitterId', '==', submitterId)
      .where('createdAt', '>=', sinceDate)
      .count()
      .get(),
    db
      .collection('brightnessSpots')
      .where('submitterId', '==', submitterId)
      .where('createdAt', '>=', sinceDate)
      .count()
      .get(),
  ]);
  return shadeSnapshot.data().count + brightnessSnapshot.data().count;
}

// spotComments の不正利用対策（コメント連投によるスパム）。
// コメントは isVerifiedUser()（電話番号SMS認証）必須のため投稿ほど気軽には量産できないものの、
// 一度認証を突破すれば無制限に連投できてしまう点は変わらないため、投稿と同じ
// checkAndIncrementRateLimit を使って対策する。
export const COMMENT_RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000; // 直近10分間（投稿側と同じ）
export const COMMENT_RATE_LIMIT_MAX_REQUESTS = 10; // コメントは投稿より軽量な操作のため、投稿より緩めの上限にする

export const VOTE_RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000; // 直近10分間
export const VOTE_RATE_LIMIT_MAX_REQUESTS = 10; // コメントの連投レート制限と同じ上限

// searchRoute（経路探索）の不正利用対策。探索1回あたりの計算コストが軽くないため、
// 投稿・コメントより短い時間窓・高頻度想定でレート制限する。
export const SEARCH_ROUTE_RATE_LIMIT_WINDOW_MS = 60 * 1000; // 直近1分間
export const SEARCH_ROUTE_RATE_LIMIT_MAX_REQUESTS = 30;

interface RateLimitState {
  windowStartMs: number;
  count: number;
}

/**
 * 固定ウィンドウ方式のレート制限の状態遷移を判定する純関数。Firestoreアクセスから
 * 分離することでunit testしやすくしている。
 */
export function decideRateLimitTransition(
  existing: RateLimitState | null,
  nowMs: number,
  windowMs: number,
  maxRequests: number
): { allow: boolean; nextState: RateLimitState } {
  const isFreshWindow = !existing || nowMs - existing.windowStartMs >= windowMs;
  if (isFreshWindow) {
    return { allow: true, nextState: { windowStartMs: nowMs, count: 1 } };
  }
  if (existing.count >= maxRequests) {
    return { allow: false, nextState: existing }; // 上限到達。カウンタは進めない
  }
  return {
    allow: true,
    nextState: { windowStartMs: existing.windowStartMs, count: existing.count + 1 },
  };
}

/**
 * `key`（呼び出し元を一意に識別する文字列、例: `comment:${uid}`）ごとのレート制限を、
 * Firestoreの`rateLimits/{key}`ドキュメント1件のカウンタで判定・更新する。
 * トランザクションで読み取り→判定→書き込みを原子的に行い、同時リクエストでの
 * カウント漏れ・二重許可を防ぐ。
 * @returns true=許可, false=レート制限超過
 */
export async function checkAndIncrementRateLimit(
  db: admin.firestore.Firestore,
  key: string,
  options: { windowMs: number; maxRequests: number; now: Date }
): Promise<boolean> {
  const ref = db.collection('rateLimits').doc(key);
  return db.runTransaction(async (tx) => {
    const snapshot = await tx.get(ref);
    const existing = snapshot.exists ? (snapshot.data() as RateLimitState) : null;
    const { allow, nextState } = decideRateLimitTransition(
      existing,
      options.now.getTime(),
      options.windowMs,
      options.maxRequests
    );
    tx.set(ref, nextState);
    return allow;
  });
}
