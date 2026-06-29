import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Auth エラーコードを日本語メッセージに変換する
String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'このメールアドレスはすでに使用されています';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'weak-password':
        return 'パスワードは6文字以上で入力してください';
      case 'user-not-found':
        return 'このメールアドレスは登録されていません';
      case 'wrong-password':
      case 'invalid-credential':
        return 'メールアドレスまたはパスワードが正しくありません';
      case 'user-disabled':
        return 'このアカウントは無効化されています';
      case 'too-many-requests':
        return 'しばらく時間をおいてから再度お試しください';
      case 'network-request-failed':
        return 'ネットワーク接続を確認してください';
      case 'requires-recent-login':
        return '再ログインが必要です。一度ログアウトして再度ログインしてください';
      case 'account-exists-with-different-credential':
        return '別のログイン方法で登録済みのメールアドレスです';
      case 'operation-not-allowed':
        return 'このログイン方法は現在利用できません';
      default:
        return '認証エラーが発生しました（${error.code}）';
    }
  }
  return error.toString();
}
