import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:health_emergency/features/auth/data/auth_repository.dart';

enum LoginErrorType { invalidCredentials, network, tooManyRequests, unknown }

class LoginState {
  const LoginState({this.isLoading = false, this.errorType});

  final bool isLoading;
  final LoginErrorType? errorType;

  LoginState copyWith({bool? isLoading, LoginErrorType? errorType}) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorType: errorType,
    );
  }
}

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
      return LoginController(ref.watch(authRepositoryProvider));
    });

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._repository) : super(const LoginState());

  final AuthRepository _repository;

  Future<void> signIn({required String email, required String password}) async {
    state = const LoginState(isLoading: true);
    try {
      await _repository.signIn(email: email, password: password);
      state = const LoginState();
    } on FirebaseAuthException catch (e) {
      state = LoginState(errorType: _mapError(e));
    } catch (_) {
      state = const LoginState(errorType: LoginErrorType.network);
    }
  }

  void clearError() {
    if (state.errorType != null) {
      state = const LoginState();
    }
  }

  LoginErrorType _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return LoginErrorType.invalidCredentials;
      case 'too-many-requests':
        return LoginErrorType.tooManyRequests;
      case 'network-request-failed':
        return LoginErrorType.network;
      default:
        return LoginErrorType.unknown;
    }
  }
}
