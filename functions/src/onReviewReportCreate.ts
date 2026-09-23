import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { countReports, exceedsReportThreshold } from './reviewReports';

/**
 * クチコミへの通報が作成されたら、累計通報件数を数えて閾値を超えていれば
 * 親レビューの status を 'pending' へ差し戻す（人力確認待ちにする）。
 * 既に 'pending' の場合は何もしない（onReviewCreate によるレート制限差し戻しと重複しても問題ない）。
 */
export const onReviewReportCreate = functions.firestore
  .document('reviews/{reviewId}/reports/{userId}')
  .onCreate(async (_snap, context) => {
    const reviewId = context.params.reviewId as string;
    const db = admin.firestore();

    const reportCount = await countReports(db, reviewId);
    if (!exceedsReportThreshold(reportCount)) return;

    const reviewRef = db.collection('reviews').doc(reviewId);
    const reviewSnap = await reviewRef.get();
    if (!reviewSnap.exists) return;
    if (reviewSnap.data()?.status === 'pending') return;

    functions.logger.info(
      `Review ${reviewId} exceeded report threshold (${reportCount} reports), moving to pending`
    );
    await reviewRef.update({ status: 'pending' });
  });
