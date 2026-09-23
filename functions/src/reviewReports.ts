// クチコミへの通報（不適切な投稿の申告）を審査するロジック。
//
// 【背景】投稿の連投レート制限(reviewModeration.ts)はあったが、内容そのものへの
// 通報・非表示フローが無かった。利用者が「通報する」を選ぶと reviews/{reviewId}/reports/{userId}
// にドキュメントが作成され（同一ユーザーの二重通報はdocIdの一致で1件に集約される）、
// 一定件数を超えると status を 'pending' へ差し戻して人力確認待ちにする
// （通報だけで即座に非公開・削除まではしない、可逆的措置）。
import * as admin from 'firebase-admin';

export const REPORT_THRESHOLD = 3; // このドキュメント自身を含め、3件を超えたら保留

/**
 * 通報件数がしきい値を超えているかどうかを判定する純関数。
 */
export function exceedsReportThreshold(reportCount: number): boolean {
  return reportCount > REPORT_THRESHOLD;
}

/**
 * reviews/{reviewId}/reports サブコレクションの件数を数える。
 */
export async function countReports(
  db: admin.firestore.Firestore,
  reviewId: string
): Promise<number> {
  const snapshot = await db
    .collection('reviews')
    .doc(reviewId)
    .collection('reports')
    .count()
    .get();
  return snapshot.data().count;
}
