import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_state.freezed.dart';

@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState({
    @Default(false) bool isLoading,
    @Default(false) bool isSuccess,

    /// Registration succeeded but a session was not obtained because email
    /// confirmation is still pending.
    /// The UI uses this to decide whether to redirect to the home page or to
    /// prompt the user to check their email for confirmation.
    @Default(false) bool needsEmailConfirmation,
    String? errorMessage,
  }) = _LoginState;
}
