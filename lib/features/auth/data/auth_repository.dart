import '../models/auth_response.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String email, String password);

  Future<AuthResponse> register(String name, String email, String password);

  Future<UserModel?> currentUser();

  Future<void> logout();
}
