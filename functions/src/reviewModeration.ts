// クチコミ投稿の不正利用対策（連投・スパム投稿のレート制限）。
//
// 【背景】chikaba_map の reviews コレクションは、認証済みユーザーであれば誰でも
// 制限なく即時公開できる状態だった（通報・非表示・承認待ちフローが存在しない）。
// 姉妹アプリ「あんしんみち」(functions/src/rateLimiting.js) の設計を参考に、
// 投稿者（userId。firestore.rules で request.auth.uid との一致を強制済みのため
// 偽装できない）ごとの直近投稿件数を見て、一定件数を超えた場合のみ status を
// 'pending'（人力承認キュー）に差し戻す。通常利用時のUX（即時公開）は変えず、
// 荒らし・誤操作による連投のみを可逆的に保留する設計。
import * as admin from 'firebase-admin';

export const RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000; // 直近10分間を見る
export const RATE_LIMIT_MAX_SUBMISSIONS = 5; // このドキュメント自身を含め、直近10分間に5件を超えたら以降は保留

/**
 * 直近 RATE_LIMIT_WINDOW_MS 以内の投稿件数（このドキュメント自身を含む）が、
 * レート制限を超えているかどうかを判定する。純関数として分離しテストしやすくしている。
 */
export function exceedsRateLimit(recentSubmissionCount: number): boolean {
  return recentSubmissionCount > RATE_LIMIT_MAX_SUBMISSIONS;
}

/**
 * userId による直近 RATE_LIMIT_WINDOW_MS 以内の reviews 投稿件数をカウントする。
 */
export async function countRecentReviewSubmissions(
  db: admin.firestore.Firestore,
  userId: string,
  now: Date
): Promise<number> {
  const sinceDate = admin.firestore.Timestamp.fromDate(
    new Date(now.getTime() - RATE_LIMIT_WINDOW_MS)
  );
  const snapshot = await db
    .collection('reviews')
    .where('userId', '==', userId)
    .where('createdAt', '>=', sinceDate)
    .count()
    .get();
  return snapshot.data().count;
}

export type ReviewModerationStatus = 'approved' | 'pending';

/**
 * 新規レビューを審査し、確定させる status を返す。
 * レート制限を超えていれば 'pending'（人力承認待ち）、そうでなければ 'approved'（即時公開）。
 */
export async function decideReviewStatus(
  db: admin.firestore.Firestore,
  userId: string,
  now: Date
): Promise<ReviewModerationStatus> {
  const recentCount = await countRecentReviewSubmissions(db, userId, now);
  return exceedsRateLimit(recentCount) ? 'pending' : 'approved';
}
