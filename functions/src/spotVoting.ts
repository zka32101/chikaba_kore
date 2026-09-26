// 投稿（shadeSpots/brightnessSpots）の相互チェック機能（確認投票＋通報、あんしんみち由来）。
//
//   confirm（確認投票）: 「この投稿は正しい」。`votes`が閾値に達した時点で、
//     人力承認待ち（'pending'）の投稿を自動承認へ引き上げる。
//   report（通報）: 「この投稿は不正確・不適切」。`reportCount`が閾値に達した時点で、
//     承認済み（'approved'）の投稿を人力再審査待ち（'pending'）へ差し戻す。
//
// いずれも「削除」ではなく「承認状態の往復」にとどめる可逆的措置。

export const SPOT_CONFIRM_APPROVE_THRESHOLD = 3; // 人力承認待ちの投稿を確認投票のみで自動承認へ引き上げる閾値
export const SPOT_REPORT_HOLD_THRESHOLD = 3; // 承認済みの投稿を再審査待ちへ差し戻す通報閾値

export type SpotVoteType = 'confirm' | 'report';

export interface SpotVoteState {
  votes: number;
  reportCount: number;
  status: string;
}

/**
 * 投票（確認/通報）が投稿の状態に与える影響を判定する純関数。Firestoreアクセスから
 * 分離することでunit testしやすくしている。
 */
export function decideSpotVoteEffect(
  current: SpotVoteState,
  voteType: SpotVoteType,
  options: { confirmApproveThreshold?: number; reportHoldThreshold?: number } = {}
): SpotVoteState {
  const confirmApproveThreshold = options.confirmApproveThreshold ?? SPOT_CONFIRM_APPROVE_THRESHOLD;
  const reportHoldThreshold = options.reportHoldThreshold ?? SPOT_REPORT_HOLD_THRESHOLD;

  if (voteType === 'confirm') {
    const votes = current.votes + 1;
    const status =
      current.status === 'pending' && votes >= confirmApproveThreshold ? 'approved' : current.status;
    return { votes, reportCount: current.reportCount, status };
  }

  const reportCount = current.reportCount + 1;
  const status =
    current.status === 'approved' && reportCount >= reportHoldThreshold ? 'pending' : current.status;
  return { votes: current.votes, reportCount, status };
}
