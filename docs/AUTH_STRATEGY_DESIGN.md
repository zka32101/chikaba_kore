# 認証方式の使い分け設計

## 概要

`docs/INTEGRATION_PLAN_ANSHINMICHI.md` の「未決定の論点」に残っていた項目。
近場まっぷ（chikaba_map）とあんしんみち（project-039）を統合する際、
両者で異なる認証方式をどう使い分けるかを整理する。

## 現状比較

| | 近場まっぷ (chikaba_map) | あんしんみち (project-039) |
|---|---|---|
| 基本認証 | Google Sign-In のみ | 匿名サインイン（起動時に自動） |
| 本人確認 | なし | 電話番号SMS認証（匿名ユーザーへ `linkWithCredential` で追加） |
| 確認状態の保存 | - | Firestore `users/{uid}.isVerified` + Auth Custom Claim `isVerified` |
| 確認状態の更新経路 | - | Cloud Functions `syncVerificationStatus` のみ（クライアントから直接書き込み不可） |
| 本人確認が必要な操作 | なし | `spotComments`（コメント投稿）のみ。投稿自体（`shadeSpots`/`brightnessSpots`）は匿名で可能 |

**重要な違い**: project-039 は「匿名認証が前提で、電話番号認証はその上位ステップとして任意追加する」設計。
近場まっぷは「Google Sign-In が前提で、匿名認証という概念自体が存在しない」設計。
これは統合時にそのまま持ち込めない差異であり、以下の方針で吸収する。

## 統合方針

### 基本方針: Google Sign-In をベースに、電話番号認証は追加リンクとして積み増す

近場まっぷ側は既に Google Sign-In でユーザーを一意に識別できているため、
project-039 のような「匿名 → 電話番号で昇格」という2段階を踏む必要はない。
統合後は以下のフローで十分:

```
Google Sign-In (uid確定)
    ↓（あんしんみち機能のコメント投稿等、本人確認必須の操作をユーザーが選んだ時）
electronic phone credential を user.linkWithCredential() で追加リンク
    ↓
Cloud Functions (syncVerificationStatus 相当) が isVerified を更新
    ↓
Custom Claim 反映のため getIdToken(true) で強制リフレッシュ
```

匿名サインインという概念は統合後の近場まっぷには導入しない。
project-039 の `FirebaseVerificationService._linkAndSync()` の実装パターン
（匿名ユーザーへのリンク）を、「Google Sign-In 済みユーザーへのリンク」に
読み替えるだけでほぼそのまま転用できる。

### 機能ごとの認証要件マッピング

| 機能領域 | 必要な認証 | 備考 |
|---|---|---|
| 施設閲覧・検索・地図表示 | 不要 | 誰でも利用可能 |
| クチコミ閲覧 | 不要 | 承認済み(`status: approved`)のみ表示 |
| クチコミ投稿 | Google Sign-In | 既存の近場まっぷの要件を維持 |
| クチコミ通報 | Google Sign-In | 既存の近場まっぷの要件を維持 |
| お気に入り登録 | Google Sign-In | 既存の近場まっぷの要件を維持 |
| プレミアム購入 | Google Sign-In | 既存の近場まっぷの要件を維持 |
| 安全ルート探索・閲覧（あんしんみち機能） | 不要 | project-039 の `searchRoute` は匿名でも可（認証必須化はレート制限対策として別途実施済み） |
| 影・明るさ投稿（あんしんみち機能） | Google Sign-In | project-039では匿名でも投稿可能だったが、統合後はアカウント一元化のためGoogle Sign-In必須に統一する |
| コメント投稿（あんしんみち機能） | Google Sign-In **+ 電話番号認証** | project-039の`isVerifiedUser()`要件をそのまま踏襲。荒らし対策の最終防衛ライン |

### 判断基準

「電話番号認証を追加要求するのは、実名性に近い担保が必要な操作（他者が読む文章を書き込む、かつ承認フローの外側にある操作）に限定する」という基準を採用する。

- クチコミ・影/明るさ投稿は、承認フロー（PR #31/#35で実装したレート制限・通報・管理者承認）で事後対応できるため、電話番号認証までは不要と判断
- コメントは即時反映かつ短文の応酬になりやすく、荒らしのコストが低いため、電話番号認証という参入障壁を維持する

## Firestore ルールへの反映イメージ

project-039 の `isVerifiedUser()` パターンをそのまま流用できる:

```firestore
function isVerifiedUser() {
  return request.auth != null && request.auth.token.isVerified == true;
}

match /comments/{commentId} {
  allow create: if isVerifiedUser() && ...;
}
```

近場まっぷ側の既存コレクション（`reviews` 等）には適用しない
（Google Sign-Inのみで十分という上記の判断のため）。

## 実装のタイミング

本人確認（電話番号認証）の実装は、あんしんみち由来の「コメント機能」を
近場まっぷに統合するタイミングで着手する。それまでは:

- `docs/INTEGRATION_PLAN_ANSHINMICHI.md` の Phase 3（1アプリ内でのモード統合）の一部として位置づける
- 単体では実装しない（近場まっぷに電話番号認証が必要な機能がまだ存在しないため、先行実装しても使い道がない）

## 未決定の残課題

- 電話番号認証のUI/UX（project-039の`phone_verification_view.dart`をベースにする想定）
- SMS送信コスト（Firebase Authの電話番号認証は無料枠を超えると課金が発生する）の試算
- 既存の近場まっぷユーザー（Google Sign-Inのみ）に対する、電話番号認証の追加リンクを促すオンボーディング動線
