import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import 'app_user.dart';
import 'auth_repository.dart';

class AuthState {
  const AuthState({
    required this.isLoading,
    this.user,
    this.errorMessage,
  });

  const AuthState.loading() : this(isLoading: true);
  const AuthState.loggedOut() : this(isLoading: false);

  final bool isLoading;
  final AppUser? user;
  final String? errorMessage;

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
    state = state.copyWith(isLoading: true, clearError: true);
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

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState.loggedOut();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authControllerProvider).user;
});
