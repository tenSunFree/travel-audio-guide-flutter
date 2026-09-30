import 'package:flutter_test/flutter_test.dart';

const _defaultTimeout = Duration(seconds: 20);
const _step = Duration(milliseconds: 100);

/// Why not `pumpAndSettle()`?
///
/// The splash page's `CityParticlesBackground`, skeleton loaders and
/// progress indicators animate forever, so `pumpAndSettle` would time out.
/// These helpers keep pumping frames until a condition becomes true, and
/// fail with a readable message instead of hanging.
extension PumpUntil on WidgetTester {
  /// Pumps until [finder] matches at least one widget.
  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = _defaultTimeout,
  }) {
    return pumpUntil(
      () => any(finder),
      timeout: timeout,
      description: finder.toString(),
    );
  }

  /// Pumps until [finder] matches nothing (e.g. a page was popped).
  Future<void> pumpUntilGone(
    Finder finder, {
    Duration timeout = _defaultTimeout,
  }) {
    return pumpUntil(
      () => !any(finder),
      timeout: timeout,
      description: 'no widgets matching $finder',
    );
  }

  /// Pumps until [condition] returns true.
  Future<void> pumpUntil(
    bool Function() condition, {
    Duration timeout = _defaultTimeout,
    String description = 'condition',
  }) async {
    final stopwatch = Stopwatch()..start();
    while (!condition()) {
      if (stopwatch.elapsed > timeout) {
        fail(
          'pumpUntil timed out after ${timeout.inSeconds}s '
          'waiting for: $description',
        );
      }
      await pump(_step);
    }
  }

  /// Keeps pumping frames for [duration] (lets entry animations finish).
  Future<void> pumpFor(Duration duration) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < duration) {
      await pump(_step);
    }
  }
}
