import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../repositories/auth_repository.dart';

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

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repo;
  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String nickname,
    required String userType,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signUp(
        email: email,
        password: password,
        nickname: nickname,
        userType: userType,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signIn(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signInWithGoogle();
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

  Future<void> upgradeToPremium() async {
    // 実際の課金処理は in-app purchase パッケージで行う
    // ここではフラグのみ更新（デモ用）
    final updated = await _repo.updateUserField({'isPremium': true});
    if (updated != null) state = AsyncValue.data(updated);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);
