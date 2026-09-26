import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase/firebase_verification_service.dart';
import '../models/user_profile.dart';
import '../services/verification_service.dart';
import 'firebase_provider.dart';

/// 本人確認（電話番号SMS認証）。`docs/AUTH_STRATEGY_DESIGN.md`の方針により、
/// 近場まっぷではGoogle Sign-In済みユーザーへの追加リンクとして扱う。
final verificationServiceProvider = Provider<VerificationService>((ref) {
  final firebaseAvailable = ref.watch(firebaseAvailableProvider);
  if (!firebaseAvailable) return LocalVerificationService();
  return FirebaseVerificationService(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    FirebaseFunctions.instance,
  );
});

/// 現在ユーザーの本人確認状態。マイページの「本人確認」項目表示に使う。
final verificationProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) {
  return ref.watch(verificationServiceProvider).getProfile();
});
