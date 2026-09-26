// 本人確認（電話番号認証）の結果をFirestore＋Custom Claimへ反映するCallable Function
// （あんしんみち由来、`docs/AUTH_STRATEGY_DESIGN.md`参照）。
//
// クライアントは`users/{uid}`へ直接書き込めない（firestore.rules参照）。Firebase Authが
// 発行するID Tokenの`phone_number`クレーム（電話番号クレデンシャルをリンクした本人のみ持つ）を
// サーバー側で検証してから書き込むことで、自己申告による本人確認済み偽装を防ぐ。
//
// isVerifiedはFirestore（`users/{uid}.isVerified`、UI表示用）に加えてAuth Custom Claim
// （`request.auth.token.isVerified`）としても設定する。firestore.rulesの`isVerifiedUser()`は
// Custom Claimのみを参照するため、`spotComments`のcreate許可判定にFirestoreの`get()`
// （追加課金・レイテンシの原因になる）が不要になる。
//
// 【重要】Custom Claimはトークン発行時点でのスナップショットのため、付与後にクライアントが
// `getIdToken(true)`で強制リフレッシュするまで反映されない
// （`lib/firebase/firebase_verification_service.dart`参照）。
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

export const syncVerificationStatus = functions.https.onCall(async (_data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'サインインが必要です');
  }
  const phoneNumber = context.auth.token.phone_number as string | undefined;
  if (!phoneNumber) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      '電話番号クレデンシャルがリンクされていません。先にPhoneAuthCredentialをlinkWithCredentialしてください'
    );
  }
  const uid = context.auth.uid;
  const db = admin.firestore();

  await db.collection('users').doc(uid).set(
    {
      isVerified: true,
      verificationMethod: 'phone',
      phoneNumber,
      updatedAt: admin.firestore.Timestamp.now(),
    },
    { merge: true }
  );

  // 既存クレームを消さないようマージしてから設定する
  const existingUser = await admin.auth().getUser(uid);
  await admin.auth().setCustomUserClaims(uid, {
    ...existingUser.customClaims,
    isVerified: true,
  });

  return { isVerified: true, verificationMethod: 'phone' };
});
