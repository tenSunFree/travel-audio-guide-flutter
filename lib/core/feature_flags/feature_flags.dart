import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compile-time switches for features that are implemented but not shipped yet.
abstract final class FeatureFlags {
  /// Account / login entry point on the "My Journey" page.
  ///
  /// Keep this `false` until login is ready to ship. The underlying auth
  /// implementation remains available and covered by tests.
  static const bool accountEntry = false;
}

/// Whether the account / login entry point is visible.
///
/// Keeping this behind a provider makes the flag easy to override in widget
/// and integration tests without changing the production constant.
final accountEntryEnabledProvider = Provider<bool>(
  (ref) => FeatureFlags.accountEntry,
);
