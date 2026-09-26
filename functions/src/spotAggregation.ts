// 承認済み投稿を道路区間(roadSegments)のスコアへ反映する集計ロジック（あんしんみち由来）。
//
// 「これまでの投稿件数」を`shadeSampleCount`/`brightnessSampleCount`として区間ごとに保持し、
// 件数に応じて新規投稿1件あたりの重みを逓減させる加重移動平均を使う。重みの下限
// （＝実質的な直近N件分のウィンドウ相当）は`MAX_EFFECTIVE_SAMPLES`で頭打ちにする。
//
// 【投稿者の信頼スコアでの重みづけ】本人確認済みユーザーの報告は、匿名（未確認）ユーザーの
// 報告よりも一件あたりの影響度を大きくする（`computeTrustWeight`参照）。
//
// 【現状の注記】`roadSegments`コレクション自体はまだクライアント側から参照されていない
// （経路探索はアセット同梱データ or 将来のCloud Functions `searchRoute` 移植後にFirestoreを
// 参照する想定）。本関数は対象ドキュメントが存在しない場合は何もしないため、
// 未移植の間も安全に動作する（`docs/PHASE3_MODE_INTEGRATION_DESIGN.md`参照）。
import * as admin from 'firebase-admin';

const MAX_EFFECTIVE_SAMPLES = 20; // これ以上は「直近20件相当」の重みで頭打ちにし、環境変化への追従性を保つ

// 本人確認済み投稿者の1件あたりの重み倍率（基準=1に対して1.5倍の影響力を持たせる）
const VERIFIED_TRUST_WEIGHT = 1.5;
// 匿名（未確認）投稿者の1件あたりの重み倍率（0にはせず、密度を稼ぐ効果は残す）
const ANONYMOUS_TRUST_WEIGHT = 0.7;

export interface SpotAggregationDelta {
  shade?: number;
  brightness?: number;
}

/**
 * @param trustWeight 投稿者の信頼度による重み倍率（既定1=従来通り）。`computeTrustWeight`参照。
 */
export async function applyApprovedSpotToRoadSegment(
  db: admin.firestore.Firestore,
  roadSegmentId: string,
  delta: SpotAggregationDelta,
  trustWeight = 1
): Promise<void> {
  const ref = db.collection('roadSegments').doc(roadSegmentId);

  await db.runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    if (!doc.exists) return; // 参照先の区間が無ければ何もしない

    const current = doc.data() ?? {};
    const update: admin.firestore.UpdateData<admin.firestore.DocumentData> = {
      lastCalculatedAt: admin.firestore.Timestamp.now(),
    };

    if (delta.shade !== undefined) {
      const currentShade = current.aggregatedShadeScore ?? current.baseShadowScore ?? 0;
      const sampleCount = current.shadeSampleCount ?? 0;
      update.aggregatedShadeScore = computeWeightedAverage(currentShade, delta.shade, sampleCount, trustWeight);
      update.shadeSampleCount = Math.min(sampleCount + 1, MAX_EFFECTIVE_SAMPLES);
    }
    if (delta.brightness !== undefined) {
      const currentBrightness = current.aggregatedBrightnessScore ?? 0;
      const sampleCount = current.brightnessSampleCount ?? 0;
      update.aggregatedBrightnessScore = computeWeightedAverage(
        currentBrightness,
        delta.brightness,
        sampleCount,
        trustWeight
      );
      update.brightnessSampleCount = Math.min(sampleCount + 1, MAX_EFFECTIVE_SAMPLES);
    }

    tx.update(ref, update);
  });
}

/**
 * 加重移動平均で新規報告値を織り込む（0〜1にクランプ）。
 * `sampleCount`件の投稿の積み重ねで得られた`current`に対し、新規1件を
 * 基準重み`1/(sampleCount+1)`× `trustWeight`で織り込む（＝`trustWeight=1`なら算術平均と等価）。
 */
export function computeWeightedAverage(
  current: number,
  newValue: number,
  sampleCount: number,
  trustWeight = 1
): number {
  const effectiveCount = Math.min(Math.max(0, sampleCount), MAX_EFFECTIVE_SAMPLES);
  const baseWeight = 1 / (effectiveCount + 1);
  const newWeight = Math.min(1, Math.max(0, baseWeight * trustWeight));
  return Math.min(1, Math.max(0, current * (1 - newWeight) + newValue * newWeight));
}

/**
 * 投稿者（`users/{uid}`ドキュメント）の信頼度に応じた重み倍率を返す。
 * @param userProfile `users/{uid}`のデータ（ドキュメントが存在しない＝一度も本人確認していない
 *   場合はundefined）
 */
export function computeTrustWeight(userProfile: { isVerified?: boolean } | undefined): number {
  return userProfile?.isVerified ? VERIFIED_TRUST_WEIGHT : ANONYMOUS_TRUST_WEIGHT;
}
