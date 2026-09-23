import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../repositories/auth_repository.dart';
import '../purchases/purchases_bootstrap.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(authServiceProvider)),
);

final authStateProvider = StreamProvider<bool>(
  (ref) => ref.watch(authRepositoryProvider).isSignedIn,
);

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final auth = ref.watch(authRepositoryProvider);
  return auth.getCurrentUser();
});

/// 現在ログイン中のユーザーが管理者(Custom Claim)かどうか。
/// クチコミの承認待ち一覧画面へのアクセス制御等に使用する。
final isAdminProvider = FutureProvider<bool>((ref) async {
  // authStateProvider を watch して、サインイン/サインアウト時に再評価する
  ref.watch(authStateProvider);
  final auth = ref.watch(authRepositoryProvider);
  return auth.isCurrentUserAdmin();
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repo;
  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.getCurrentUser();
      if (user != null) await linkPurchasesToUser(user.uid);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signInWithGoogle();
      // RevenueCat の app_user_id を Firebase UID に一致させる
      // (revenuecatWebhook が users/{uid} を直接更新できるようにするため)
      await linkPurchasesToUser(user.uid);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// 任意フィールドを更新（プロフィール編集などで汎用利用）
  Future<void> updateUserField(Map<String, dynamic> fields) async {
    final updated = await _repo.updateUserField(fields);
    if (updated != null) state = AsyncValue.data(updated);
  }

  Future<void> updateUserType(String userType) async {
    final updated = await _repo.updateUserField({'userType': userType});
    if (updated != null) state = AsyncValue.data(updated);
  }

}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);
