import 'extensions.dart';

class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'メールアドレスを入力してください';
    if (!value.isValidEmail) return '有効なメールアドレスを入力してください';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'パスワードを入力してください';
    if (!value.isValidPassword) return 'パスワードは6文字以上で入力してください';
    return null;
  }

  static String? nickname(String? value) {
    if (value == null || value.isEmpty) return 'ニックネームを入力してください';
    if (!value.isValidNickname) return 'ニックネームは2〜20文字で入力してください';
    return null;
  }

  static String? reviewText(String? value) {
    if (value == null || value.isEmpty) return 'レビューを入力してください';
    if (value.length < 10) return 'レビューは10文字以上で入力してください';
    if (value.length > 500) return 'レビューは500文字以内で入力してください';
    return null;
  }
}
