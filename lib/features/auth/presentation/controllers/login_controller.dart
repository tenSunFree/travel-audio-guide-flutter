import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/auth/di/auth_providers.dart';
import 'package:flutter_travel_audio_guide/features/auth/presentation/controllers/login_state.dart';

class LoginController extends StateNotifier<LoginState> {
  LoginController({required this.ref}) : super(const LoginState());

  final Ref ref;

  Future<void> signIn({required String email, required String password}) {
    return _submit(() async {
      await ref
          .read(authRepositoryProvider)
          .signInWithPassword(email: email, password: password);
      return false;
    });
  }

  Future<void> signUp({required String email, required String password}) {
    return _submit(
      () => ref
          .read(authRepositoryProvider)
          .signUpWithPassword(email: email, password: password)
          .then((hasSession) => !hasSession),
    );
  }

  Future<void> _submit(Future<bool> Function() action) async {
    // Invariant: a new submit never inherits previous success flags.
    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      needsEmailConfirmation: false,
      errorMessage: null,
    );
    try {
      final needsEmailConfirmation = await action();
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        needsEmailConfirmation: needsEmailConfirmation,
        errorMessage: null,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        needsEmailConfirmation: false,
        errorMessage: e.map(
          server: (e) => e.message,
          download: (e) => e.message,
          localStorage: (e) => e.message,
        ),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        needsEmailConfirmation: false,
        errorMessage: '登入失敗，請稍後再試',
      );
    }
  }
}

final StateNotifierProvider<LoginController, LoginState>
loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
      return LoginController(ref: ref);
    });
