import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/masters/data/masters_providers.dart';
import '../network/api_exception.dart';
import 'app_user.dart';
import 'auth_repository.dart';

class AuthState {
  const AuthState({
    required this.isLoading,
    this.user,
    this.errorMessage,
    this.initializing = false,
  });

  /// Restoring the saved session at startup (vs. an interactive sign-in).
  const AuthState.loading() : this(isLoading: true, initializing: true);
  const AuthState.loggedOut() : this(isLoading: false);

  final bool isLoading;
  final AppUser? user;
  final String? errorMessage;
  final bool initializing;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    AppUser? user,
    bool clearUser = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState.loading()) {
    restore();
  }

  final AuthRepository _repository;

  Future<void> restore() async {
    state = const AuthState.loading();
    final user = await _repository.restoreSession();
    state = AuthState(isLoading: false, user: user);
  }

  Future<bool> signIn({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.signIn(username: username, password: password);
      state = AuthState(isLoading: false, user: user);
      return true;
    } on ApiException catch (e) {
      state = AuthState(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  /// Changes the signed-in user's password. Returns an error message or null.
  Future<String?> changePassword({required String currentPassword, required String newPassword}) async {
    final user = state.user;
    if (user == null) return 'Not signed in.';
    try {
      await _repository.changePassword(
        userId: user.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = AuthState(isLoading: false, user: user.copyWith(mustChangePassword: false));
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState.loggedOut();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(appDatabaseProvider));
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authControllerProvider).user;
});
