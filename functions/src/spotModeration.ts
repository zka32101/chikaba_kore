// 投稿の自動承認判定＋NGワードフィルタ（あんしんみち由来、`docs/PHASE3_MODE_INTEGRATION_DESIGN.md`参照）。
//
// 【重要】ステータス決定はクライアントを信用せずサーバー側（本ファイル）で行う。
// firestore.rulesはクライアントからの新規作成時 status/moderationStatus を 'pending' 固定に
// 強制しており、'approved' への遷移はCloud Functions（Admin SDK、ルールの制約を受けない）
// からのみ行われる。
import * as admin from 'firebase-admin';

export interface ModerationConfig {
  region: string;
  autoApproveAnonymous: boolean;
  trustScoreThreshold: number;
  ngWords: string[];
}

// 【本格実装】将来的には運営者がデプロイ無しで辞書を更新できるようRemote Config経由の
// 同期を検討する（project-039のremoteConfigSync.js参照）。現時点では固定値のみ。
export const DEFAULT_NG_WORDS = ['死ね', 'クズ', 'バカ野郎'];

/**
 * 地域別モデレーション設定を読み込む。config/moderation ドキュメントを唯一の正とする。
 */
export async function loadModerationConfig(
  db: admin.firestore.Firestore
): Promise<ModerationConfig> {
  const doc = await db.collection('config').doc('moderation').get();
  if (!doc.exists) {
    return {
      region: 'JP',
      autoApproveAnonymous: true,
      trustScoreThreshold: 0.5,
      ngWords: DEFAULT_NG_WORDS,
    };
  }
  const d = doc.data() ?? {};
  return {
    region: d.region ?? 'JP',
    autoApproveAnonymous: d.autoApproveAnonymous ?? true,
    trustScoreThreshold: d.trustScoreThreshold ?? 0.5,
    // Array.isArray チェックはFirestoreに不正な型（文字列等）が入っていた場合の防御。
    ngWords:
      Array.isArray(d.ngWords) && d.ngWords.length > 0 ? d.ngWords : DEFAULT_NG_WORDS,
  };
}

/**
 * @param requiresManualReview true の場合、地域のモデレーション設定に関わらず常に
 *   'pending'（人力承認キュー）に留め置く。「人通りが少ない」等、客観的な観測（日陰・雨よけの
 *   有無）と異なり主観的・偏見の影響を受けやすい投稿種別の荒らし対策として使う。
 */
export function decideInitialStatus(
  moderationConfig: Pick<ModerationConfig, 'autoApproveAnonymous'>,
  options: { requiresManualReview?: boolean } = {}
): 'approved' | 'pending' {
  if (options.requiresManualReview) return 'pending';
  return moderationConfig.autoApproveAnonymous ? 'approved' : 'pending';
}

// NGワード判定前の正規化: 半角/全角スペース・中黒・ハイフン・アンダースコアを除去してから比較する。
// 「死　ね」「死・ね」のように区切り文字を挟んでNGワードフィルタを回避する典型的な手口を防ぐ。
const EVASION_CHARS_PATTERN = /[\s・\-_]/g;

function normalizeForNgWordMatch(text: string): string {
  return text.replace(EVASION_CHARS_PATTERN, '');
}

export function containsNgWord(text: string | undefined, ngWords: string[] = DEFAULT_NG_WORDS): boolean {
  if (!text) return false;
  const normalized = normalizeForNgWordMatch(text);
  return ngWords.some((word) => normalized.includes(word));
}

/** コメントのモデレーション判定（NGワードのみ）。 */
export function decideCommentModerationStatus(
  text: string | undefined,
  ngWords: string[] = DEFAULT_NG_WORDS
): 'approved' | 'rejected' {
  return containsNgWord(text, ngWords) ? 'rejected' : 'approved';
}
