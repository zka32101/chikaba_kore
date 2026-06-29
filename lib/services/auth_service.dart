import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentFirebaseUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String nickname,
    required String userType,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final now = DateTime.now();
      final user = UserModel(
        uid: uid,
        nickname: nickname,
        userType: userType,
        selectedCity: '東京23区',
        createdAt: now,
        updatedAt: now,
      );
      await _firestore.collection('users').doc(uid).set(user.toFirestore());
      return user;
    } on FirebaseAuthException catch (e) {
      appLogger.e('SignUp error', error: e);
      rethrow;
    }
  }

  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _fetchUserModel(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      appLogger.e('SignIn error', error: e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> _fetchUserModel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel?> getCurrentUserModel() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _fetchUserModel(uid);
  }

  /// Google アカウントでサインイン（新規ユーザーは自動的に Firestore ドキュメントを作成）
  Future<UserModel?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // ユーザーがキャンセル

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;

      // 既存ユーザーか確認
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }

      // 新規ユーザー → Firestore ドキュメント作成
      final now = DateTime.now();
      final user = UserModel(
        uid: uid,
        nickname: googleUser.displayName ?? 'ユーザー',
        profileImageUrl: googleUser.photoUrl,
        userType: 'visitor',
        selectedCity: '東京23区',
        createdAt: now,
        updatedAt: now,
      );
      await _firestore.collection('users').doc(uid).set(user.toFirestore());
      return user;
    } on FirebaseAuthException catch (e) {
      appLogger.e('Google SignIn error', error: e);
      rethrow;
    } catch (e) {
      appLogger.e('Google SignIn error', error: e);
      rethrow;
    }
  }

  /// パスワードリセットメールを送信する
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// アカウントを完全削除（Firestore ドキュメント → Firebase Auth の順）
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    await _firestore.collection('users').doc(uid).delete();
    await user.delete();
  }

  /// Firestore のユーザードキュメントを部分更新する
  Future<UserModel?> updateUserField(Map<String, dynamic> fields) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    await _firestore.collection('users').doc(uid).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return _fetchUserModel(uid);
  }
}
