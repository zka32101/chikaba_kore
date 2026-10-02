/**
 * 「訪問」実績（users/{userId}.visitCount）の判定ロジック。
 * お気に入り（favorites）のstatusが'will_go'（行ってきた）に"なった"タイミングのみ
 * +1する。'will_go'のまま他フィールドが更新された場合や、'will_go'から
 * 'want_to_go'に戻した場合は対象外（実績は取り消さない）。
 */
export function shouldIncrementVisitOnFavoriteWrite(
  beforeStatus: string | undefined,
  afterStatus: string | undefined
): boolean {
  return afterStatus === 'will_go' && beforeStatus !== 'will_go';
}
