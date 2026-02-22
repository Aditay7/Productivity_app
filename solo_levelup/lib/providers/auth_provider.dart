import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/repositories/auth_repository.dart';
import '../models/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthState {
  final bool isLoading;
  final AuthUser? user;
  final String? error;
  final bool isInitialized;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isInitialized = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    AuthUser? user,
    String? error,
    bool? isInitialized,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._repository) : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final token = await _storage.read(key: 'jwt');
      if (token != null && token.isNotEmpty) {
        // Token exists, verify it by fetching user profile
        final user = await _repository.getMe();
        state = state.copyWith(
          user: user,
          isLoading: false,
          isInitialized: true,
        );
      } else {
        state = state.copyWith(isLoading: false, isInitialized: true);
      }
    } catch (e) {
      // Token likely expired or invalid
      await _storage.delete(key: 'jwt');
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: 'Session expired. Please log in again.',
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.login(email, password);
      // Safe the token securely
      await _storage.write(key: 'jwt', value: response.token);
      state = state.copyWith(user: response.user, isLoading: false);
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.register(username, email, password);
      await _storage.write(key: 'jwt', value: response.token);
      state = state.copyWith(user: response.user, isLoading: false);
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _storage.delete(key: 'jwt');
    // Clear user, but keep the initialised flag to true so UI knows boot is done
    state = AuthState(isInitialized: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
