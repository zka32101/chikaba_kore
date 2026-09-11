import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;
  AuthRepository(this._authService);

  Stream<bool> get isSignedIn =>
      _authService.authStateChanges.map((user) => user != null);

  Future<UserModel?> signInWithGoogle() => _authService.signInWithGoogle();

  Future<void> signOut() => _authService.signOut();

  Future<void> deleteAccount() => _authService.deleteAccount();

  Future<UserModel?> getCurrentUser() => _authService.getCurrentUserModel();

  Future<UserModel?> updateUserField(Map<String, dynamic> fields) =>
      _authService.updateUserField(fields);
}
