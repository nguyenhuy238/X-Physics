import '../../../core/constants/app_constants.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;

  final _users = const [
    UserModel(
      id: 'usr_student_nam',
      name: 'Nguyen Van Nam',
      email: AppConstants.demoStudentEmail,
      role: 'STUDENT',
    ),
    UserModel(
      id: 'usr_admin',
      name: 'Admin User',
      email: AppConstants.demoAdminEmail,
      role: 'ADMIN',
    ),
  ];

  @override
  Future<AuthResponse> login(String email, String password) async {
    final user = _users.firstWhere(
      (item) => item.email == email,
      orElse: () => throw StateError('Invalid credentials'),
    );
    if (password != AppConstants.demoPassword) {
      throw StateError('Invalid credentials');
    }
    _currentUser = user;
    return AuthResponse(
      user: user,
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
    );
  }

  @override
  Future<AuthResponse> register(
    String name,
    String email,
    String password,
  ) async {
    final user = UserModel(
      id: 'usr_mock_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      role: 'STUDENT',
    );
    _currentUser = user;
    return AuthResponse(
      user: user,
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
    );
  }

  @override
  Future<UserModel?> currentUser() async => _currentUser;

  @override
  Future<void> logout() async {
    _currentUser = null;
  }
}
