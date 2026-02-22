import '../../core/network/api_client.dart';
import '../../models/auth_user.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  /// Login with email and password
  Future<AuthResponse> login(String email, String password) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );

    return AuthResponse.fromJson(response['data']);
  }

  /// Register a new user
  Future<AuthResponse> register(
    String username,
    String email,
    String password,
  ) async {
    final response = await _apiClient.post(
      '/auth/register',
      body: {'username': username, 'email': email, 'password': password},
    );

    return AuthResponse.fromJson(response['data']);
  }

  /// Get current authenticated user profile
  Future<AuthUser> getMe() async {
    final response = await _apiClient.get('/auth/me');
    return AuthUser.fromJson(response['data']);
  }
}
