import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/core/router/app_router.dart';
import 'package:flutter_travel_audio_guide/features/auth/di/auth_providers.dart';
import 'package:flutter_travel_audio_guide/features/auth/presentation/controllers/login_controller.dart';
import 'package:flutter_travel_audio_guide/features/auth/presentation/controllers/login_state.dart';
import 'package:go_router/go_router.dart';

/// Login is an OPTIONAL feature page, not the app entrance.
///
/// It can be reached in two ways:
/// 1. Pushed manually (e.g., from MyJourney's account button) — after a successful
///    login it should pop back to the previous screen.
/// 2. Redirected from a protected route with a `from` query — after a successful
///    login it should go to the original destination.
///
/// This page is entirely responsible for navigating away from /login. The router's
/// redirect rules intentionally do not redirect already-signed-in users away from
/// /login to avoid both sides navigating on the same auth-state change.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUpMode = false;

  static const _teal = Color(0xFF007F83);

  @override
  void initState() {
    super.initState();
    // Deep-link edge case: the user is already signed-in but opens /login directly
    // (bookmark, notification link, etc.). Since the router no longer continuously
    // redirects signed-in users away from /login, check once on initial load only —
    // no need to subscribe to the stream.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(isSignedInProvider)) {
        _navigateAfterAuth();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final controller = ref.read(loginControllerProvider.notifier);
    if (_isSignUpMode) {
      controller.signUp(email: email, password: password);
    } else {
      controller.signIn(email: email, password: password);
    }
  }

  /// Validate `from` to avoid unsafe redirects or /login loops:
  /// - must exist and be non-empty
  /// - must be an internal relative path with no scheme/authority
  ///   (rejects e.g. `//example.com/path`, which starts with '/' but is
  ///   actually protocol-relative and points off-app)
  /// - must not point back to /login itself
  String? _safeFrom() {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    if (from == null || from.isEmpty) return null;
    final uri = Uri.tryParse(from);
    if (uri == null) return null;
    if (uri.hasScheme || uri.hasAuthority) return null;
    if (!uri.path.startsWith('/')) return null;
    if (uri.path.startsWith(AppRoutes.login)) return null;
    return from;
  }

  void _navigateAfterAuth() {
    final from = _safeFrom();
    if (from != null) {
      context.go(from);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    ref.listen<LoginState?>(loginControllerProvider, (previous, next) {
      if (next == null || next.isLoading || !next.isSuccess) return;
      if (next.needsEmailConfirmation) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('註冊成功，請至信箱完成驗證後登入')));
        return;
      }
      _navigateAfterAuth();
    });
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Guest-first: whether pushed or redirected (no pop history), allow
        // leaving the login page to browse the app.
        actions: [
          TextButton(
            onPressed: state.isLoading
                ? null
                : () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.home),
            child: const Text('先逛逛'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.headphones_rounded, size: 56, color: _teal),
                  const SizedBox(height: 12),
                  Text(
                    _isSignUpMode ? '建立帳號' : '歡迎回來',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F3A3D),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || !value.contains('@')) {
                        return '請輸入有效的 Email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(
                      labelText: '密碼',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return '密碼至少需要 6 碼';
                      }
                      return null;
                    },
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _teal),
                      onPressed: state.isLoading ? null : _submit,
                      child: state.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isSignUpMode ? '註冊' : '登入'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: state.isLoading
                        ? null
                        : () => setState(() => _isSignUpMode = !_isSignUpMode),
                    child: Text(_isSignUpMode ? '已經有帳號？改為登入' : '還沒有帳號？前往註冊'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
